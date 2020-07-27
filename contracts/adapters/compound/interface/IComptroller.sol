pragma solidity ^0.6.0;

interface IComptroller {
    function claimComp(address) external;
    function compAccrued(address) external view returns (uint);
}