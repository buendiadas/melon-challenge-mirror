pragma solidity ^0.6.0;

import "./interface/ICETH.sol";
import "./interface/ICERC20.sol";
import "./interface/IComptroller.sol";

import "../common/interface/IERC20.sol";
import "../common/interface/IAdapter.sol";
import "../common/IntegrationSignatures.sol";
import "../common/Constants.sol";

/// @title Compound Adapter
/// @dev The Compound adapter is the main output of the Melon Challenge
/// Integrates with the SimpleVault, offering 3 main functions: SupplyAsset, Redeem Asset, and Claim Compound
/// In order to simplify, it doesn't allow ETH as an input

contract CompoundAdapter is IAdapter, IntegrationSignatures, Constants {

    event AssetSupplied(address indexed token, address cToken, uint256 amount);
    event AssetRedeemed(address indexed token, address cToken, uint256 amount);
    event CompoundClaimed(address indexed comptroller);

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
        if (_methodSelector != COMPOUND_CLAIM_SELECTOR) {
            (address token, address cToken, uint256 amount) = __decodeCallArgs (_encodedArgs);
            if (_methodSelector == COMPOUND_SUPPLY_SELECTOR) {
                return __initializeOutgoing(token, amount);
            } else if (_methodSelector == COMPOUND_REDEEM_SELECTOR) {
                return __initializeOutgoing(cToken, amount);
            } else {
              revert("Method non supported");
             }
        } else {
            outgoingAssets_ = new address[](0);
            outgoingAmounts_ = new uint[](0);
        }
    }


    /// @notice Supplies assets on Compound
    /// @param _encodedCallArgs Encoded order parameters, following the structure under `__decodeCallArgs()`

    function supplyAssets(bytes calldata _encodedCallArgs)
        external
        returns (address[] memory incomingAssets)
    {
        (
            address _token,
            address _cToken,
            uint256 _amount

        ) = __decodeCallArgs(_encodedCallArgs);
        __supplyErc20ToCompound(_token, _cToken, _amount);

        incomingAssets = new address[](2);
        incomingAssets[0] = _cToken;
        emit AssetSupplied(_token, _cToken, _amount);
        return incomingAssets;
    }


    /// @notice Supplies assets on Compound
    /// @param _encodedCallArgs Encoded order parameters, following the structure under `__decodeCallArgs()`

    function redeemAssets(bytes calldata _encodedCallArgs)
        external
        returns (address[] memory incomingAssets)
    {
        (
            address _token,
            address _cToken,
            uint256 _cTokenAmount

        ) = __decodeCallArgs(_encodedCallArgs);
        __redeemCErc20Tokens(_token, _cToken, _cTokenAmount);

        incomingAssets = new address[](1);
        incomingAssets[0] = _token;
        return incomingAssets;
    }

    ///@notice Claims compound for `msg.sender` accrued over time by supplying assets

    function claimComp(bytes calldata _encodedCallArgs)
        external
        returns (address[] memory incomingAssets)
    {
        address _comptroller = abi.decode(_encodedCallArgs, (address));
        __claimComp(_comptroller);
        incomingAssets = new address[](1);
        incomingAssets[0] = COMP_ASSET_ADDRESS;
    }


     /// @notice Supplies an amount of ERC20 tokens, receiving a `cToken` in exchange
     /// @param _erc20Contract Address of the supplied ERC20 asset
     /// @param _cErc20Contract Address of the cToken which will be received in exchange
     /// @param _amount Number of tokens that will be supplied

    function __supplyErc20ToCompound(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 _amount
    )
        internal
        returns (bool)
    {
        uint256 initialERC20Balance = IERC20(_erc20Contract).balanceOf(address(this));
        bool success = IERC20(_erc20Contract).transferFrom(msg.sender, address(this), _amount);
        
        require(success, "TransferFrom failed"); //  Simplistic, must consider different ERC20 implementations (NON compliant)
        uint256 afterReceiptERC20Balance = IERC20(_erc20Contract).balanceOf(address(this));
        
        require(afterReceiptERC20Balance >= initialERC20Balance, "Overflow");
        IERC20(_erc20Contract).approve(_cErc20Contract, _amount);
        ICERC20(_cErc20Contract).mint(_amount); // <-- Potentially dangerous, could lead to Reentrancy
        uint256 receivedBalance = IERC20(_cErc20Contract).balanceOf(address(this));
        IERC20(_cErc20Contract).transfer(msg.sender, receivedBalance);
        return true;
    }

     /// @notice Redeems an specified amount of cTokens, receiving an amount of the underlying asset
     /// @param _erc20Contract Address of the supplied ERC20 asset
     /// @param _cErc20Contract Address of the cToken which will be received in exchange
     /// @param _amount Number of tokens that will be supplied

    function __redeemCErc20Tokens(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 _amount
    ) internal returns (bool)
    {
        uint256 initialCERC20Balance = IERC20(_cErc20Contract).balanceOf(address(this));
        bool success = IERC20(_cErc20Contract).transferFrom(msg.sender, address(this), _amount);
        
        require(success, "TransferFrom failed"); //  Simplistic, must consider different ERC20 implementations (NON compliant)
        uint256 afterReceiptCERC20Balance = IERC20(_cErc20Contract).balanceOf(address(this));
        
        require(afterReceiptCERC20Balance >= initialCERC20Balance, "Overflow");
        IERC20(_cErc20Contract).approve(_cErc20Contract, _amount);        
        uint cBalanceIERC20 = IERC20(_cErc20Contract).balanceOf(address(this));
        ICERC20(_cErc20Contract).redeem(_amount);
        
        uint256 underlyingAssetReceived = IERC20(_erc20Contract).balanceOf(address(this));
        IERC20(_erc20Contract).transfer(msg.sender, underlyingAssetReceived);
        emit AssetRedeemed(_cErc20Contract,_erc20Contract, cBalanceIERC20);
        return true;
    }

    ///@notice Claims compound for `msg.sender` accrued over time by supplying assets

    function __claimComp(address _comptroller) internal returns (bool) {
        IComptroller(_comptroller).claimComp(msg.sender);
        emit CompoundClaimed(_comptroller);
        return true;
    }


    /// @dev Helper to decode the encoded arguments

    function __decodeCallArgs(bytes memory _encodedCallArgs)
        public
        pure
        returns (
            address token,
            address cToken,
            uint256 amount
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

        /// @dev Helper to decode the encoded arguments

    function __initializeOutgoing(address _token, uint _amount)
        public
        pure
        returns (
            address[] memory outgoingAssets_,
            uint256[] memory outgoingAmounts_
        )
    {
         outgoingAssets_ = new address[](1);
         outgoingAssets_[0] = _token;
         outgoingAmounts_ = new uint[](1);
         outgoingAmounts_[0] = _amount;
    }


}