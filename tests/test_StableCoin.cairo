%lang starknet

from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.math import assert_not_equal
from starkware.starknet.common.syscalls import get_contract_address

from interfaces.IMyVault import IMyVault
from interfaces.IStableCoin import IStableCoin

const ADMIN = 111;
const FREN = 222;
const NAME = 756157777;
const SYMBOL = 7561577;
const ETHPRICESOURCE = 999;
const MINCOLLPERCENT = 150;
const ZERO = 0;
const TOKENNAME = 565;
const TOKENSYMBOL = 566;
const VAULT = 721;

@external 
func __setup__() {
    %{
        context.context_stablecoin_address = deploy_contract("./src/StableCoin.cairo", [ids.ETHPRICESOURCE, ids.MINCOLLPERCENT, ids.ZERO, ids.TOKENNAME, ids.TOKENSYMBOL, ids.VAULT]).contract_address
    %}
    // tempvar stablecoin_address: felt;
    // %{
    //     ids.stablecoin_address = context.context_stablecoin_address
    //     context.contex_stablecoin_address = deploy_contract("./src/StableCoin.cairo", [ids.ETHPRICESOURCE, ids.MINCOLLPERCENT, ids.TOKENNAME, ids.TOKENSYMBOL, ids.stablecoin_address]).contract_address
    // %}
    return ();
}

@external
func test_deploy{syscall_ptr: felt*, range_check_ptr}(
) {
    tempvar stablecoin_address: felt;

    %{
        ids.stablecoin_address = context.context_stablecoin_address
    %}

    let (_name) = IStableCoin.name(stablecoin_address);
    assert TOKENNAME = _name;

    let (_symbol) = IStableCoin.symbol(stablecoin_address);
    assert TOKENSYMBOL = _symbol;

    let (this) = get_contract_address();
    let (_owner) = IStableCoin.owner(stablecoin_address);
    assert this = _owner;

    let (_debtCeiling) = IStableCoin.getDebtCeiling(stablecoin_address);
    let ten_as_uint256: Uint256 = Uint256(10000000000000000000, 0);
    assert ten_as_uint256 = _debtCeiling;

    let (_closingFee) = IStableCoin.getClosingFee(stablecoin_address);
    let fifty_as_uint256: Uint256 = Uint256(50,0);
    assert fifty_as_uint256 = _closingFee;

    let (_openingFee) = IStableCoin.getOpeningFee(stablecoin_address);
    let zero_as_uint256: Uint256 = Uint256(0,0);
    assert zero_as_uint256 = _openingFee;

    let (_tokenPeg) = IStableCoin.getTokenPriceSource(stablecoin_address);
    let one_as_uint256: Uint256 = Uint256(100000000, 0);
    assert one_as_uint256 = _tokenPeg;

    %{  
        print("Successful deployment of the contract; constructor successfully implemented")
    %}
    return ();
}

@external
func test_mock_call_return_ethPrice{syscall_ptr: felt*, range_check_ptr}(
) {
    tempvar stablecoin_address: felt;
    %{
        ids.stablecoin_address = context.context_stablecoin_address
    %}

    let price_as_uint256: Uint256 = Uint256(152038000000, 0);
    %{ stop_mock = mock_call(ids.stablecoin_address, "getEthPriceSource", [152038000000, 0]) %}
    let res: Uint256 = IStableCoin.getEthPriceSource(stablecoin_address);
    %{ stop_mock() %}
    assert res = Uint256(152038000000, 0);

    return();
}

@external
func test_createVault{syscall_ptr: felt*, range_check_ptr}(
) {
    alloc_locals;
    tempvar stablecoin_address: felt;
    %{
        ids.stablecoin_address = context.context_stablecoin_address
    %}

    //  needs myvault transferownership
    let id: Uint256 = IStableCoin.createVault(stablecoin_address);

    let (eq) = uint256_eq(Uint256(1,0), id);
    assert 1 = eq;


    return();
}