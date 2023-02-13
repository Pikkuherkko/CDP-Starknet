%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

// Oracle Interface Definition
// const EMPIRIC_ORACLE_ADDRESS = 0x446812bac98c08190dee8967180f4e3cdcd1db9373ca269904acb17f67f7093;
// const PAIR_ID = 19514442401534788;  // str_to_felt("ETH/USD")

@contract_interface
namespace IEmpiricOracle {
    func get_spot_median(pair_id: felt) -> (
        price: felt,
        decimals: felt,
        last_updated_timestamp: felt,
        num_sources_aggregated: felt
    ) {
    }
}

// Address: 0x7e00d496e324876bbc8531f2d9a82bf154d1a04a50218ee74cdd372f75a551a
// Public key: 0x7e52885445756b313ea16849145363ccb73fb4ab0440dbac333cf9d13de82b9
// Private key: 0xe3e70682c2094cac629f6fbed82c07cd