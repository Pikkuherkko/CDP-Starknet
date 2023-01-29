%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IMyVault {
    func burn(tokenId: Uint256){
    }

    func mint(to: felt, tokenId: Uint256){
    }
}