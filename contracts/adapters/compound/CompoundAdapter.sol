  
pragma solidity ^0.6.0;


import "./interface/ICETH.sol";
import "./interface/ICERC20.sol";
import "./interface/IComptroller.sol";

import "../common/interface/IERC20.sol";
import "../common/interface/IAdapter.sol";
import "../common/IntegrationSignatures.sol"; 

import "../common/Constants.sol";

contract CompoundAdapter is IAdapter, IntegrationSignatures, Constants {
    event MyLog(string, uint256);
    
    
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
        (address suppliedAsset, address incomingAssets, uint256 outgoingAssetAmount)  = __decodeCallArgs (_encodedArgs);
        outgoingAssets_ = new address[](1);
        outgoingAssets_[0] = suppliedAsset;
        outgoingAmounts_ = new uint[](1);
        outgoingAmounts_[0] = outgoingAssetAmount;
    }
    
    
    /// @notice Supplies assets on Compound
    /// @param _encodedCallArgs Encoded order parameters
    function supplyAssets(bytes calldata _encodedCallArgs)
        external
        returns (address[] memory incomingAssets)
    {
        (
            address _suppliedAsset,
            address _cToken,
            uint256 _suppliedAmount

        ) = __decodeCallArgs(_encodedCallArgs);
        __supplyErc20ToCompound(_suppliedAsset, _cToken, _suppliedAmount);
        
        incomingAssets = new address[](2);
        incomingAssets[0] = _suppliedAsset;
        incomingAssets[1] = COMP_ASSET_ADDRESS;
        return incomingAssets;
    }
    

    function __supplyErc20ToCompound(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 _amount
    ) 
        public
        returns (uint) {
        IERC20(_erc20Contract).transferFrom(msg.sender, address(this), _amount);
        IERC20(_erc20Contract).approve(_cErc20Contract, _amount);
        ICERC20(_cErc20Contract).mint(_amount); // Reentrancy ? ?
        uint256 receivedBalance = IERC20(_cErc20Contract).balanceOf(address(this)); // :S <---------------
        IERC20(_cErc20Contract).transfer(msg.sender, receivedBalance);
        return receivedBalance;
    }

    function redeemCErc20Tokens(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 _amount
    ) public returns (bool) {

        uint256 redeemResult;
        IERC20(_cErc20Contract).transferFrom(msg.sender, address(this), _amount);
        IERC20(_cErc20Contract).approve(_cErc20Contract, _amount);
        
            // Retrieve your asset based on a cToken amount
        redeemResult = ICERC20(_cErc20Contract).redeem(_amount);
        uint256 underlyingAssetReceived = IERC20(_erc20Contract).balanceOf(address(this)); // <------ SAME
        IERC20(_erc20Contract).transfer(msg.sender, underlyingAssetReceived);
        return true;
    }
    
    function claimComp() public returns (bool) {
        IComptroller(COMPTROLLER).claimComp(msg.sender);
        return true;
    }
    
        
        /// @dev Helper to decode the encoded arguments
    function __decodeCallArgs(bytes memory _encodedCallArgs)
        public
        pure
        returns (
            address outgoingAsset_,
            address incomingAssets_,
            uint256 outgoingAssetsAmount_
        )
    {
        return abi.decode(
            _encodedCallArgs,
            (
                address,
                address,
                uint256
                            )
        );
    }
    
    fallback() external payable {}
}