pragma solidity ^0.6.0;

import "./IAdapter.sol";

/// @title Adapter interface
/// @dev No need to add anything here, this just defines the required adapter functions to implement
interface IAdapter {
    function parseOutgoingAssets(bytes4, bytes calldata) external view returns (address[] memory, uint256[] memory);
}
