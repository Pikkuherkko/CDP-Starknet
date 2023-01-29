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