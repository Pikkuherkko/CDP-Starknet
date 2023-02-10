%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IStableCoin {
    func onlyVaultOwner(vaultID: Uint256) {
    }

    func getDebtCeiling() -> (res: Uint256) {
    }

    func getClosingFee() -> (res: Uint256) {
    }

    func getOpeningFee() -> (res: Uint256) {
    }

    func getTokenPriceSource() -> (res: Uint256) {
    }

    func getEthPriceSource() -> (res: Uint256) {
    }

    func calculateCollateralProperties(collateral: Uint256, debt: Uint256) -> (collateralValueTimes100: Uint256, debtValue: Uint256) {
    }

    func isValidCollateral(collateral: Uint256, debt: Uint256) -> (bool: felt) {
    }

    func createVault() -> (id: Uint256) {
    }

    func destroyVault(vaultID: Uint256) {
    }

    func transferVault(vaultID: Uint256, to: felt) {
    }

    func depositCollateral(vaultID: Uint256, amount: Uint256) {
    }

    func withdrawCollateral(vaultID: Uint256, amount: Uint256) {
    }

    func borrowToken(vaultID: Uint256, amount: Uint256) {
    }

    func payBackToken(vaultID: Uint256, amount: Uint256) {
    }

    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func totalSupply() -> (totalSupply: Uint256) {
    }

    func decimals() -> (decimals: felt) {
    }

    func balanceOf(account: felt) -> (balance: Uint256) {
    }

    func allowance(owner: felt, spender: felt) -> (remaining: Uint256) {
    }

    func owner() -> (owner: felt) {
    }

    func transfer(recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func transferFrom(sender: felt, recipient: felt, amount: Uint256) -> (success: felt) {
    }

    func approve(spender: felt, amount: Uint256) -> (success: felt) {
    }

    func increaseAllowance(spender: felt, added_value: Uint256) -> (success: felt) {
    }

    func decreaseAllowance(spender: felt, subtracted_value: Uint256) -> (success: felt) {
    }

    func mint(to: felt, amount: Uint256) {
    }

    func transferOwnership(newOwner: felt) {
    }

    func renounceOwnership() {
    }
}