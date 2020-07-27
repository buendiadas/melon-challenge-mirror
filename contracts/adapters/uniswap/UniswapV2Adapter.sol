pragma solidity ^0.6.0;

import "../common/interface/IAdapter.sol";
import "../common/IntegrationSignatures.sol";
import "../common/interface/IERC20.sol";
import "../common/Constants.sol";
import "./IUniswapExchange.sol";



// 1. Rename contract, @title comment, and file to your adapter name
/// @title My Adapter contract
/// @dev This is the main file that you'll need to edit to implement your adapter's behavior
contract UniswapV2Adapter is IAdapter, IntegrationSignatures, Constants {
    
    /// @notice Parses the fund assets to be spent given a specified adapter method and set of encoded args
    /// @param _methodSelector The bytes4 selector for the function signature being called
    /// @param _encodedArgs The encoded params to use in the integration call
    /// @return outgoingAssets_ The fund's assets to use in the integration call
    /// @return outgoingAmounts_ The amount of each of the fund's assets to use in the integration call
    
    function parseOutgoingAssets(bytes4 _methodSelector, bytes calldata _encodedArgs)
        external
        view
        override
        returns (address[] memory outgoingAssets_, uint256[] memory outgoingAmounts_)
    {
        (address[] memory path, uint256 outgoingAssetAmount, address incomingAssets)  = __decodeCallArgs (_encodedArgs);
        outgoingAssets_ = new address[](1);
        outgoingAssets_[0] = path[0];
        outgoingAmounts_ = new uint[](1);
        outgoingAmounts_[0] = outgoingAssetAmount;
    }
    
    // 3. Add your own adapter functions here. You can have one or many primary functions and helpers.

    // YOUR CODE HERE
    
    /// @notice Trades assets on Uniswap
    /// @param _encodedCallArgs Encoded order parameters
    function takeOrder(bytes calldata _encodedCallArgs)
        external
        returns (address[] memory incomingAssets)
    {
        (
            address[] memory path,
            uint256 outgoingAssetAmount,
            address incomingAsset
        ) = __decodeCallArgs(_encodedCallArgs);
        
           
        __swapTokenforToken(path, outgoingAssetAmount);
            
        incomingAssets = new address[](1);
        incomingAssets[0] = incomingAsset;
        return incomingAssets;
    }
        /// @dev Helper to execute a swap of ERC20 to ERC20
    function __swapTokenforToken(address[] memory _path, uint256 _outgoingAssetAmount)
        public
    {
       IERC20(_path[0]).transferFrom(msg.sender, address(this), _outgoingAssetAmount);
       IERC20(_path[0]).approve(UNISWAP_EXCHANGE_ASSET, _outgoingAssetAmount);
       
        IUniswapV2Router2(UNISWAP_EXCHANGE_ASSET).swapExactTokensForTokens(
            _outgoingAssetAmount,
             0,
             _path,
             msg.sender,
            1605272178 // <----------------- Check this out!
        );
    }    
        /// @dev Helper to decode the encoded arguments
    function __decodeCallArgs(bytes memory _encodedCallArgs)
        private
        pure
        returns (
            address[] memory path_,
            uint256 outgoingAssetsAmount_,
            address incomingAssets_
        )
    {
        return abi.decode(
            _encodedCallArgs,
            (
                address[],
                uint256,
                address            )
        );
    }
}
