pragma solidity ^0.6.0;

import "./interface/ICETH.sol";
import "./interface/ICERC20.sol";
import "./interface/IComptroller.sol";

import "../common/interface/IERC20.sol";
import "../common/interface/IAdapter.sol";
import "../common/IntegrationSignatures.sol";
import "../common/Constants.sol";

contract CompoundAdapter is IAdapter, IntegrationSignatures, Constants {
    
    event AssetSupplied(address indexed suppliedAsset, address cToken, uint256 amount);
    event AssetRedeemed(address indexed redeemedAsset, address underlying, uint256 amount);

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
        (address token, address cToken, uint256 amount) = __decodeCallArgs (_encodedArgs);

        if (_methodSelector == COMPOUND_SUPPLY_SELECTOR) {
            outgoingAssets_ = new address[](1);
            outgoingAssets_[0] = token;
            outgoingAmounts_ = new uint[](1);
            outgoingAmounts_[0] = amount;
        } else if (_methodSelector == COMPOUND_REDEEM_SELECTOR) {
            outgoingAssets_ = new address[](1);
            outgoingAssets_[0] = cToken;
            outgoingAmounts_ = new uint[](1);
            outgoingAmounts_[0] = amount;
        } else {
            revert("Method non supported");
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
        incomingAssets[1] = COMP_ASSET_ADDRESS;
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

    function claimComp() public returns (bool) {
        IComptroller(COMPTROLLER).claimComp(msg.sender);
        return true;
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
        returns (uint) {
        IERC20(_erc20Contract).transferFrom(msg.sender, address(this), _amount);
        IERC20(_erc20Contract).approve(_cErc20Contract, _amount);
        ICERC20(_cErc20Contract).mint(_amount); // Reentrancy ? ?
        uint256 receivedBalance = IERC20(_cErc20Contract).balanceOf(address(this)); // :S <---------------
        IERC20(_cErc20Contract).transfer(msg.sender, receivedBalance);
        return 1;
    }


     /// @notice Redeems an specified amount of cTokens, receiving an amount of the underlying asset
     /// @param _erc20Contract Address of the supplied ERC20 asset
     /// @param _cErc20Contract Address of the cToken which will be received in exchange
     /// @param _amount Number of tokens that will be supplied

    function __redeemCErc20Tokens(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 _amount
    ) internal returns (bool) {

        uint256 redeemResult;
        IERC20(_cErc20Contract).transferFrom(msg.sender, address(this), _amount);
        IERC20(_cErc20Contract).approve(_cErc20Contract, _amount);
        uint cBalanceIERC20 = IERC20(_cErc20Contract).balanceOf(address(this));
        redeemResult = ICERC20(_cErc20Contract).redeem(_amount);
        uint256 underlyingAssetReceived = IERC20(_erc20Contract).balanceOf(address(this)); // <------ SAME
        IERC20(_erc20Contract).transfer(msg.sender, underlyingAssetReceived);
        emit AssetRedeemed(_cErc20Contract,_erc20Contract, cBalanceIERC20);
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

}