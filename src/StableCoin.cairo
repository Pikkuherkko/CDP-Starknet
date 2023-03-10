// this thing is highly experimental, I do not recommend copying
// there is still a lot to do to get this working properly
// author: Pikkuherkko

%lang starknet
from starkware.cairo.common.math import assert_nn, assert_not_zero, assert_le, split_felt
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.uint256 import Uint256, uint256_add, uint256_le, uint256_lt, uint256_sub, uint256_mul, uint256_unsigned_div_rem

from openzeppelin.token.erc20.library import ERC20
from openzeppelin.token.erc20.IERC20 import IERC20
from openzeppelin.access.ownable.library import Ownable
from openzeppelin.security.reentrancyguard.library import ReentrancyGuard
from interfaces.IMyVault import IMyVault
from interfaces.IEmpiricOracle import IEmpiricOracle

// events

@event
func CreateVault(vaultID: Uint256, creator: felt) {
}

@event
func DestroyVault(vaultID: Uint256) {
}

@event
func TransferVault(vaultID: Uint256, from_: felt, to: felt) {
}

@event
func DepositCollateral(vaultID: Uint256, amount: Uint256) {
}

@event
func WithdrawCollateral(vaultID: Uint256, amount: Uint256) {
}

@event
func BorrowToken(vaultID: Uint256, amount: Uint256) {
}

@event
func PayBackToken(vaultID: Uint256, amount: Uint256, closingFee: Uint256) {
}

@event
func BuyRiskyVault(vaultID: Uint256, owner: felt, buyer: felt, amountPaid: Uint256) {
}

// storage functions

@storage_var
func wethAddress() -> (res: felt) {
}


@storage_var
func ethPriceSource() -> (res: felt) {
}


@storage_var
func _minimumCollateralPercentage() -> (res: Uint256) {
}

@storage_var
func erc721() -> (res: felt) {
}

@storage_var
func vaultCount() -> (res: Uint256) {
}

@storage_var
func debtCeiling() -> (res: Uint256) {
}

@storage_var
func closingFee() -> (res: Uint256) {
}

@storage_var
func openingFee() -> (res: Uint256) {
}

@storage_var
func treasury() -> (res: Uint256) {
}

@storage_var
func tokenPeg() -> (res: Uint256) {
}

@storage_var
func vaultExistence(vault: Uint256) -> (res: felt) {
}

@storage_var
func vaultOwner(vault: Uint256) -> (res: felt) {
}

@storage_var
func vaultCollateral(vault: Uint256) -> (res: Uint256) {
}

@storage_var
func vaultDebt(vault: Uint256) -> (res: Uint256) {
}

@storage_var
func stabilityPool() -> (res: felt) {
}

// constructor

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    weth: felt,
    ethPriceSourceAddress: felt,
    minimumCollateralPercentage: Uint256,
    name: felt,
    symbol: felt,
    vaultAddress: felt,
    owner: felt
) {
    ERC20.initializer(name, symbol, 18);
    Ownable.initializer(owner);
    wethAddress.write(weth);
    assert_not_zero(ethPriceSourceAddress);
    let zero_as_uint256: Uint256 = Uint256(0,0);
    let (le) = uint256_lt(zero_as_uint256, minimumCollateralPercentage);
    assert le = 1;
    let ten_as_uint256: Uint256 = Uint256(10000000000000000000, 0);
    debtCeiling.write(ten_as_uint256); // ten
    let fifty_as_uint256: Uint256 = Uint256(50,0);
    closingFee.write(fifty_as_uint256); // 0.5%
    openingFee.write(zero_as_uint256);
    ethPriceSource.write(ethPriceSourceAddress);
    stabilityPool.write(0);
    let one_as_uint256: Uint256 = Uint256(100000000, 0);
    tokenPeg.write(one_as_uint256); // $1
    erc721.write(vaultAddress);
    _minimumCollateralPercentage.write(minimumCollateralPercentage);
    return();
}

// modifiers

func onlyVaultOwner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    vaultID: Uint256
) {
    let (existence) = vaultExistence.read(vaultID);
    with_attr error_message("Vault does not exist") {
        assert existence = 1;
    }
    let (owner) = vaultOwner.read(vaultID);
    let (caller) = get_caller_address();
    with_attr error_message("Vault is not owned by you") {
        assert owner = caller;
    }
    return();
}

// view functions

@view
func getDebtCeiling{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: Uint256
) {
    let (_debtCeiling) = debtCeiling.read();
    return (res=_debtCeiling);
}

@view
func getClosingFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: Uint256
) {
    let (_closingFee) = closingFee.read();
    return (res=_closingFee);
}

@view
func getOpeningFee{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: Uint256
) {
    let (_openingFee) = openingFee.read();
    return (res=_openingFee);
}

@view
func getTokenPriceSource{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: Uint256
) {
    let (_tokenPeg) = tokenPeg.read();
    return (res=_tokenPeg);
}

@view
func getEthPriceSource{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    res: Uint256
) {
    const PAIR_ID = 19514442401534788;  // str_to_felt("ETH/USD")
    let (priceSource) = ethPriceSource.read();
    let (price, decimals, last_updated_timestamp, num_sources_aggregated) = IEmpiricOracle.get_spot_median(priceSource, PAIR_ID);
    let res: Uint256 = split_felt(price);
    return(res=res);
}

func calculateCollateralProperties{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collateral: Uint256, debt: Uint256
) -> (
    collateralValueTimes100: Uint256, debtValue: Uint256
) {
    alloc_locals;
    let (ethPrice) = getEthPriceSource();
    let zero_as_uint256: Uint256 = Uint256(0,0);
    let (le) = uint256_le(zero_as_uint256, ethPrice);
    assert le = 1;

    let (tokenPeg) = getTokenPriceSource();
    let (le) = uint256_le(zero_as_uint256, tokenPeg);
    assert le = 1;

    let (local collateralValue, _) = uint256_mul(collateral, ethPrice);
    let (le) = uint256_le(collateral, collateralValue);
    assert le = 1;

    let (local debtValue, _) = uint256_mul(debt, tokenPeg);
    let (le) = uint256_le(debt, debtValue);
    assert le = 1;
    
    let hundred_as_uint256: Uint256 = Uint256(100, 0);
    let (local collateralValueTimes100, _) = uint256_mul(collateralValue, hundred_as_uint256);
    let (lt) = uint256_lt(collateralValue, collateralValueTimes100);
    assert lt = 1;

    return(collateralValueTimes100=collateralValueTimes100, debtValue=debtValue);
}

func isValidCollateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    collateral: Uint256, debt: Uint256
) -> (
    bool: felt
) {
    alloc_locals;
    let (collateralValueTimes100, debtValue) = calculateCollateralProperties(collateral, debt);
    let (collateralPercentage: Uint256, rem: Uint256) = uint256_unsigned_div_rem(collateralValueTimes100, debtValue);
    let (minimumCollateralPercentage) = _minimumCollateralPercentage.read();

    let (le) = uint256_le(minimumCollateralPercentage, collateralPercentage);
    assert le = 1;
    return(bool=1);
}

// external functions

@external
func createVault{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    id: Uint256
) {
    alloc_locals;
    let (caller) = get_caller_address();

    let id: Uint256 = vaultCount.read();
    let one_as_uint256 = Uint256(1,0);
    let (local vaultCount_after, _) = uint256_add(id, one_as_uint256);
    vaultCount.write(vaultCount_after);
    let (le) = uint256_le(id, vaultCount_after);
    assert le = 1;

    vaultExistence.write(id, 1);
    vaultOwner.write(id, caller);

    CreateVault.emit(id, caller);

    let (_erc721) = erc721.read();
    IMyVault.mint(_erc721, caller, id);

    return(id=id);
}

@external
func destroyVault{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    vaultID: Uint256
) {
    alloc_locals;
    ReentrancyGuard.start();
    onlyVaultOwner(vaultID);
    let (_vaultDebt) = vaultDebt.read(vaultID);
    let zero_as_uint256: Uint256 = Uint256(0,0);
    with_attr error_message("Vault has outstanding debt") {
        assert _vaultDebt = zero_as_uint256;
    }
    
    let (caller) = get_caller_address();
    let (_vaultCollateral) = vaultCollateral.read(vaultID);

    let zero_as_uint256 : Uint256 = Uint256(0,0);
    let (lt) = uint256_lt(zero_as_uint256, _vaultCollateral);
    if (lt == 1) {
        ERC20.transfer(caller, _vaultCollateral);
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    
    let (_erc721) = erc721.read();
    IMyVault.burn(_erc721, vaultID);
    vaultExistence.write(vaultID, 1);
    vaultOwner.write(vaultID, 0);
    vaultCollateral.write(vaultID, zero_as_uint256);
    vaultDebt.write(vaultID, zero_as_uint256);

    DestroyVault.emit(vaultID);
    ReentrancyGuard.end();
    return();
}

@external
func transferVault{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    vaultID: Uint256, to: felt
) {
    onlyVaultOwner(vaultID);

    let (_erc721) = erc721.read();
    IMyVault.burn(_erc721, vaultID);
    IMyVault.mint(_erc721, to, vaultID);

    let (caller) = get_caller_address();
    TransferVault.emit(vaultID, caller, to);
    return();
}

// msg.value not supported, ERC20 implemented
@external
func depositCollateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    vaultID: Uint256, amount: Uint256
) {
    alloc_locals;
    onlyVaultOwner(vaultID);
    let (_vaultCollateral) = vaultCollateral.read(vaultID);
    let (local newCollateral, _) = uint256_add(_vaultCollateral, amount);
    let (le) = uint256_le(_vaultCollateral, newCollateral);
    assert le = 1;

    let (caller) = get_caller_address();
    let (this) = get_contract_address();
    let (weth) = wethAddress.read();
    IERC20.transferFrom(weth, caller, this, amount);

    vaultCollateral.write(vaultID, newCollateral);
    DepositCollateral.emit(vaultID, amount);
    return();
}

@external
func withdrawCollateral{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    vaultID: Uint256, amount: Uint256
) {
    alloc_locals;
    onlyVaultOwner(vaultID);
    ReentrancyGuard.start();

    let (_vaultCollateral) = vaultCollateral.read(vaultID);
    with_attr error_message("Vault does not have enough collateral") {
        let (le) = uint256_le(amount, _vaultCollateral);
        assert le = 1;
    }
    let (local newCollateral) = uint256_sub(_vaultCollateral, amount);
    let (_vaultDebt) = vaultDebt.read(vaultID);

    let zero_as_uint256 : Uint256 = Uint256(0,0);
    let (lt) = uint256_lt(zero_as_uint256, _vaultDebt);
    if (lt == 1) {
        with_attr error_message("Withdrawal would put vault below minimum collateral percentage") {
            let (bool) = isValidCollateral(newCollateral, _vaultDebt);
            assert bool = 1;
        }
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar syscall_ptr = syscall_ptr;
        tempvar pedersen_ptr = pedersen_ptr;
        tempvar range_check_ptr = range_check_ptr;
    }

    let (caller) = get_caller_address();
    vaultCollateral.write(vaultID, newCollateral);
    let (weth) = wethAddress.read();
    IERC20.approve(weth, caller, amount);
    IERC20.transfer(weth, caller, amount);
    WithdrawCollateral.emit(vaultID, amount);
    ReentrancyGuard.end();
    return();
}

@external
func borrowToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    vaultID: Uint256, amount: Uint256
) {
    alloc_locals;
    onlyVaultOwner(vaultID);
    let zero_as_uint256: Uint256 = Uint256(0,0);
    with_attr error_message("Must borrow non-zero amount") {
        let (lt) = uint256_lt(zero_as_uint256, amount);
        assert lt = 1;
    }
    let _totalSupply: Uint256 = ERC20.total_supply();
    let (local newSupply, _) = uint256_add(_totalSupply, amount);
    let (_debtCeiling) = debtCeiling.read();
    with_attr error_message("borrowToken: Cannot mint over totalSupply.") {
        let (le) = uint256_le(newSupply, _debtCeiling);
        assert le = 1;
    }

    let (_vaultDebt) = vaultDebt.read(vaultID);
    let (local newDebt, _) = uint256_add(_vaultDebt, amount);
    let (lt) = uint256_lt(_vaultDebt, newDebt);
    assert lt = 1;

    let (_vaultCollateral) = vaultCollateral.read(vaultID);
    with_attr error_message("Borrow would put vault below minimum collateral percentage") {
        let (bool) = isValidCollateral(_vaultCollateral, newDebt);
        assert bool = 1;
    }

    vaultDebt.write(vaultID, newDebt);

    let (caller) = get_caller_address();
    mint(caller, amount);
    BorrowToken.emit(vaultID, amount);
    return();
}

@external
func payBackToken{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    vaultID: Uint256, amount: Uint256
) {
    alloc_locals;
    onlyVaultOwner(vaultID);
    let (caller) = get_caller_address();
    let (bal) = ERC20.balance_of(caller);
    with_attr error_message("Token balance too low") {
        let (le) = uint256_le(amount, bal);
        assert le = 1;
    }
    let (_vaultDebt) = vaultDebt.read(vaultID);
    with_attr error_message("Vault debt less than amount to pay back") {
        let (le) = uint256_le(amount, _vaultDebt);
        assert le = 1;
    }

    let (ethPrice) = getEthPriceSource();
    let (tokenPeg) = getTokenPriceSource();
    let (_closingFee) = closingFee.read();
    let ten_k_as_uint256: Uint256 = Uint256(10000, 0);
    let (local denominator, _) = uint256_mul(ethPrice, ten_k_as_uint256);
    let (local num, _) = uint256_mul(amount, _closingFee);
    let (local numerator, _) = uint256_mul(num, tokenPeg);
    let (closingFeeEth: Uint256, rem: Uint256) = uint256_unsigned_div_rem(numerator, denominator);

    let (_vaultDebt) = vaultDebt.read(vaultID);
    let (newDebt) = uint256_sub(_vaultDebt, amount);
    vaultDebt.write(vaultID, newDebt);

    let (_vaultCollateral) = vaultCollateral.read(vaultID);
    let (newVaultCollateral) = uint256_sub(_vaultCollateral, closingFeeEth);
    vaultCollateral.write(vaultID, newVaultCollateral);

    let (_treasury: Uint256) = treasury.read();
    let (_vaultCollateral) = vaultCollateral.read(_treasury);
    let (local newVaultCollateral, _) = uint256_add(_vaultCollateral, closingFeeEth);
    vaultCollateral.write(_treasury, newVaultCollateral);

    ERC20._burn(caller, amount);
    PayBackToken.emit(vaultID, amount, closingFeeEth);
    return();
}

@external
func buyRiskyVault{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    vaultID: Uint256
) {
    alloc_locals;
    let (_vaultExistence) = vaultExistence.read(vaultID);
    with_attr error_message("Vault does not exist") {
        assert _vaultExistence = 1;
    }
    //
    // here this function could be disabled for public by requiring caller to be stabilityPool
    //
    let (_vaultCollateral) = vaultCollateral.read(vaultID);
    let (_vaultDebt) = vaultDebt.read(vaultID);
    let (_collateralValueTimes100: Uint256, _debtValue: Uint256) = calculateCollateralProperties(_vaultCollateral, _vaultDebt);

    let (collateralPercentage: Uint256, rem: Uint256) = uint256_unsigned_div_rem(_collateralValueTimes100, _debtValue);
    let (minimumCollateralPercentage) = _minimumCollateralPercentage.read();

    let (lt) = uint256_lt(collateralPercentage, minimumCollateralPercentage);
    with_attr error_message("Vault is not below minimum collateral percentage") {
        assert lt = 1;
    }

    let (maximumDebtValue: Uint256, rem: Uint256) = uint256_unsigned_div_rem(_collateralValueTimes100, minimumCollateralPercentage);

    let (ethPrice: Uint256) = getEthPriceSource();
    let (maximumDebt: Uint256, rem: Uint256) = uint256_unsigned_div_rem(maximumDebtValue, ethPrice);

    let (debtDifference: Uint256) = uint256_sub(_vaultDebt, maximumDebt);

    let (caller) = get_caller_address();
    let (caller_bal: Uint256) = balanceOf(caller);
    let (le) = uint256_le(debtDifference, caller_bal);
    with_attr error_message("Token balance too low to pay off outstanding debt") {
        assert le = 1;
    }

    let (previusOwner) = vaultOwner.read(vaultID);

    vaultOwner.write(vaultID, caller);
    vaultDebt.write(vaultID, maximumDebt);

    let (tokenPeg) = getTokenPriceSource();
    let (_closingFee) = closingFee.read();
    let ten_k_as_uint256: Uint256 = Uint256(10000, 0);
    let (local denominator, _) = uint256_mul(ethPrice, ten_k_as_uint256);
    let (local num, _) = uint256_mul(debtDifference, _closingFee);
    let (local numerator, _) = uint256_mul(num, tokenPeg);
    let (closingFeeEth: Uint256, rem: Uint256) = uint256_unsigned_div_rem(numerator, denominator);

    let (newVaultCollateral: Uint256) = uint256_sub(_vaultCollateral, closingFeeEth);
    vaultCollateral.write(vaultID, newVaultCollateral);

    let (_treasury: Uint256) = treasury.read();
    let (treasuryVaultCollateral: Uint256) = vaultCollateral.read(_treasury);
    let (local newTreasuryVaultCollateral, _) = uint256_add(treasuryVaultCollateral, closingFeeEth);
    vaultCollateral.write(_treasury, newTreasuryVaultCollateral);

    ERC20._burn(caller, debtDifference);

    let (_erc721) = erc721.read();
    IMyVault.burn(_erc721, vaultID);
    IMyVault.mint(_erc721, caller, vaultID);

    BuyRiskyVault.emit(vaultID, previusOwner, caller, debtDifference);
    return();
}

// OZ ERC20

@view
func name{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (name: felt) {
    return ERC20.name();
}

@view
func symbol{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (symbol: felt) {
    return ERC20.symbol();
}

@view
func totalSupply{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    totalSupply: Uint256
) {
    let (totalSupply: Uint256) = ERC20.total_supply();
    return (totalSupply=totalSupply);
}

@view
func decimals{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    decimals: felt
) {
    return ERC20.decimals();
}

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (
    balance: Uint256
) {
    return ERC20.balance_of(account);
}

@view
func allowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    owner: felt, spender: felt
) -> (remaining: Uint256) {
    return ERC20.allowance(owner, spender);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    return Ownable.owner();
}

@external
func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt, amount: Uint256
) -> (success: felt) {
    return ERC20.transfer(recipient, amount);
}

@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, amount: Uint256
) -> (success: felt) {
    return ERC20.transfer_from(sender, recipient, amount);
}

@external
func approve{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, amount: Uint256
) -> (success: felt) {
    return ERC20.approve(spender, amount);
}

@external
func increaseAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, added_value: Uint256
) -> (success: felt) {
    return ERC20.increase_allowance(spender, added_value);
}

@external
func decreaseAllowance{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    spender: felt, subtracted_value: Uint256
) -> (success: felt) {
    return ERC20.decrease_allowance(spender, subtracted_value);
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, amount: Uint256
) {
    Ownable.assert_only_owner();
    ERC20._mint(to, amount);
    return ();
}

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    newOwner: felt
) {
    Ownable.transfer_ownership(newOwner);
    return ();
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    Ownable.renounce_ownership();
    return ();
}