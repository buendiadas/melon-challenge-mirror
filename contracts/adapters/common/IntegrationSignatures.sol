pragma solidity ^0.6.0;

/// @title Integration Signatures Contract
/// @dev Create a selector constant for each of your callable adapter methods (not including parseOutgoingAssets())
contract IntegrationSignatures {
    // 1. Create a constant for the function selectors of each of your adapter methods
    // For example:
    // bytes4 constant public TAKE_ORDER_SELECTOR = bytes4(keccak256("takeOrder(bytes)"));

    // bytes4 constant public MY_FUNCTION_SELECTOR = bytes4(keccak256("myFunction(bytes)"));
    bytes4 constant public COMPOUND_SUPPLY_SELECTOR = bytes4(keccak256("supplyAssets(bytes)"));
    bytes4 constant public COMPOUND_REDEEM_SELECTOR = bytes4(keccak256("redeemAssets(bytes)"));
}
