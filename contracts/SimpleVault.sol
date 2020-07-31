pragma solidity ^0.6.0;

import "./IAdapter.sol";
import "./IERC20.sol";

/// @title Simple Vault contract
/// @dev (Heavily) simplified version of a Melon Vault for the purposes of
/// demonstrating an integration adapter. Assume that there is no internal system of account,
/// and asset balances will just be checked elsewhere via IERC20(asset).balanceOf(vaultAddress).
contract SimpleVault {
    mapping (address => bool) public isOwnedAsset;
    
    event AssetApproved(address suppliedAsset, address adapter, uint256 amount);
    
    /// @notice Universal method for calling third party contract functions through adapters
    /// @param _adapter Adapter of the integration on which to execute a call
    /// @param _methodSignature The function signature of the adapter method to execute
    /// @param _encodedMethodArgs Encoded arguments specific to the adapter method
    function callOnIntegration(
        address _adapter,
        string calldata _methodSignature,
        bytes calldata _encodedMethodArgs
    )
        external
    {
        // The adapter first tells the Vault which fund assets (and how much) to use in the call
        bytes4 methodSelector = bytes4(keccak256(bytes(_methodSignature)));
        (
            address[] memory outgoingAssets,
            uint256[] memory outgoingAmounts
        ) = IAdapter(_adapter).parseOutgoingAssets(methodSelector, _encodedMethodArgs);

        // Approve the adapter for each asset and amount to be used in the call
        for (uint256 i = 0; i < outgoingAssets.length; i++) {
            address asset = outgoingAssets[i];
            uint256 amount = outgoingAmounts[i];
            require(isOwnedAsset[asset]);
            IERC20(asset).approve(_adapter, amount);
            emit AssetApproved(asset, _adapter, amount);
        }

        // The adapter is then called with the specified method and args.
        // IMPORTANT: The adapter's returnData must be an array of the asset addresses
        // that it has received in the call.
        (bool success, bytes memory returnData) = _adapter.call(
            abi.encodeWithSignature(_methodSignature, _encodedMethodArgs)
        );
        require(success, string(returnData));

        // The incoming assets are marked as owned, if not already owned by the fund
        address[] memory incomingAssets = abi.decode(returnData, (address[]));
        for (uint256 i = 0; i < incomingAssets.length; i++) {
            address asset = incomingAssets[i];
            if (!isOwnedAsset[asset]) isOwnedAsset[asset] = true;
        }

        // The outgoing assets are marked as unowned, if their ERC20 balance is 0
        for (uint256 i = 0; i < outgoingAssets.length; i++) {
            address asset = outgoingAssets[i];
            if (IERC20(asset).balanceOf(address(this)) == 0) isOwnedAsset[asset] = false;
        }
    }

    /// @notice Adds an asset to the vault's owned assets
    /// @param _asset The asset to add to the vault
    /// @dev This exists purely to aid with writing tests,
    /// since you'll need some balance in order to test your adapter.
    function addOwnedAsset(address _asset) external {
        if (
            !isOwnedAsset[_asset] &&
            IERC20(_asset).balanceOf(address(this)) > 0
        )
        {
            isOwnedAsset[_asset] = true;
        }
    }
}
