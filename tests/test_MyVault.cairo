%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_equal

from interfaces.IMyVault import IMyVault

const ADMIN = 111;
const FREN = 222;
const NAME = 756157777;
const SYMBOL = 7561577;

@external 
func __setup__() {
    %{
        context.context_myvault_address = deploy_contract("./src/MyVault.cairo", [ids.NAME, ids.SYMBOL, ids.ADMIN]).contract_address
    %}
    return ();
}

@external
func test_deploy{syscall_ptr: felt*, range_check_ptr}(
) {
    tempvar myvault_address: felt;

    %{
        ids.myvault_address = context.context_myvault_address
    %}

    let (_name) = IMyVault.name(myvault_address);
    assert NAME = _name;

    let (owner) = IMyVault.owner(myvault_address);
    assert ADMIN = owner;

    %{  
        print("Successful deployment of the contract; constructor successfully implemented")
    %}
    return ();
}

@external
func test_mint_and_burn{syscall_ptr: felt*, range_check_ptr}(
) {
    tempvar myvault_address: felt;

    %{
        ids.myvault_address = context.context_myvault_address
    %}
    
    let tokenId: Uint256 = Uint256(1,0);

    %{ stop_prank_minter = start_prank(ids.ADMIN, ids.myvault_address) %}
    IMyVault.mint(myvault_address, ADMIN, tokenId);
    %{ stop_prank_minter() %}

    let (minted_token_owner) = IMyVault.ownerOf(myvault_address, tokenId);
    assert ADMIN = minted_token_owner;

    %{ stop_prank_minter = start_prank(ids.ADMIN, ids.myvault_address) %}
    IMyVault.burn(myvault_address, tokenId);
    %{ stop_prank_minter() %}

    %{ expect_revert(error_message="ERC721: owner query for nonexistent token") %}
    let (minted_token_owner) = IMyVault.ownerOf(myvault_address, tokenId);

    %{  
        print("mint and burn successful")
    %}
    return ();
}
