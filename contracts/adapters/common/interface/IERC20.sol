pragma solidity ^0.6.0;

/// @title Simple IERC20 interface
/// @dev If you need access to decimals, symbol, name, feel free to add them here
interface IERC20 {
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}
