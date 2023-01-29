%lang starknet
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc721.library import ERC721

// storage vars


@storage_var
func admin_storage() -> (admin: felt) {
}

// view functions 

// constructor

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    name: felt, symbol: felt, owner: felt
) {
    ERC721.initializer(name, symbol);
    admin_storage.write(owner);
    return ();
}

// external functions

@external
func setAdmin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _admin: felt
) {
    let (admin) = admin_storage.read();
    let (caller) = get_caller_address();
    assert admin = caller;
    admin_storage.write(_admin);
    return();
}

@external
func _transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    from_: felt, to: felt, tokenId: Uint256
) {
    with_attr error_message("Amount must be positive. Got: {amount}.") {
        assert 1 = 0;
    }
    return();
}

@external
func burn{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    tokenId: Uint256
) {
    let (caller) = get_caller_address();
    assert caller = owner;
    ERC721._burn(tokenId);
    return();
}

@external
func mint{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    to: felt, tokenId: Uint256
) {
    let (caller) = get_caller_address();
    assert caller = owner;
    ERC721._mint(to, tokenId);
    return();
}
