// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";


/*
Website: https://thefreedomcoin.org
Whitepaper: docs.thefreedomcoin.org
Instagram: https://www.instagram.com/_freedomcoin
Telegram: https://t.me/FREEDeth
**/

contract FreedomCoin is ERC20, Ownable, ERC20Permit {
    mapping(address => bool) public blacklist;
    address public charityAddress = 0x047c0D746D42fF4cEe7d2CB1FBf5c0D090267931;
    address public marketingDevAddress = 0x0331535b9f37EB41F437EA0cfE345ABB9d102A1A;
    address public holderIncentive;

    constructor(address initialOwner)
        ERC20("Freedom Coin", "FREED")
        Ownable(initialOwner)
        ERC20Permit("Freedom")
    {
        uint256 totalSupply = 7000000 * (10 ** uint256(decimals()));
        _mint(initialOwner, totalSupply);
        uint256 charityAmount = totalSupply * 1 / 100; // 1%
        // uint256 incentiveAmount = totalSupply * 1 / 100; // 1%
        uint256 marketingDevAmount = totalSupply * 9 / 1000; // 0.9%
        transfer(charityAddress, charityAmount);
        // transfer(holderIncentive, incentiveAmount);
        transfer(marketingDevAddress, marketingDevAmount);
    }

    function setHolderIncentive(address _holder) public onlyOwner{
        holderIncentive = _holder;
    }
}
