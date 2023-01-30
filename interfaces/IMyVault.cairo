%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IMyVault {
    func burn(tokenId: Uint256){
    }

    func mint(to: felt, tokenId: Uint256){
    }

    func transferOwnership(newOwner: felt) {
    }

    func _transferFrom(from_: felt, to: felt, tokenId: Uint256) {
    }

    func name() -> (name: felt) {
    }

    func owner() -> (owner: felt) {
    }

    func ownerOf(tokenId: Uint256) -> (owner: felt) {
    }
}