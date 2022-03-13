// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface CErc20 {
    
    function borrowIndex() external returns (uint);

    function mint(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function balanceOf(address owner) external view returns (uint);

    function balanceOfUnderlying(address owner) external returns (uint);

    function borrowRatePerBlock() external view returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function getCash() external view returns (uint);

    function accrueInterest() external returns (uint);

}

interface Comptroller {

    function markets(address) external returns (bool, uint256);

    function enterMarkets(address[] calldata) external returns (uint256[] memory);

    function getAccountLiquidity(address) external view returns (uint256, uint256, uint256);

}



interface Erc20 {

    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address src, address dst, uint wad) external returns (bool);


}

interface Monkey{ 

    function setCharacters(uint256 _tokenId, uint _strength, uint _accountIndex) external returns (uint, uint);

    function createDemoMonkey(address _owner) external returns (uint256);

    function balanceOf(address owner) external returns (uint256);

    function findMonkeyIdsOfAddress(address owner) external returns (uint256[] memory);
    
    function getMonkey(uint256 tokenId) external returns (uint256 strength, uint256 accountIndex);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    

}