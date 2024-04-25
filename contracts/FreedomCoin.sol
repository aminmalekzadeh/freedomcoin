// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract FreedomCoin is ERC20, Ownable, ERC20Permit {
    mapping(address => bool) public blacklist;
    address public charityAddress = 0xb93131eE7BE304c183790d3F6EdCDd978024F93f;
    address public marketingDevAddress = 0xCA59eE89c37C78B29EC6Da733f66a2217042C7D3;
    address public holderIncentive = 0xBF3C56f4D317A11e5796df613E52081A34462410;

    constructor(address initialOwner)
        ERC20("Freedom Coin", "FREED")
        Ownable(initialOwner)
        ERC20Permit("Freedom")
    {
        uint256 totalSupply = 7000000 * (10 ** uint256(decimals()));
        _mint(initialOwner, totalSupply);
        uint256 charityAmount = totalSupply * 1 / 100; // 1%
        uint256 incentiveAmount = totalSupply * 1 / 100; // 1%
        uint256 marketingDevAmount = totalSupply * 9 / 1000; // 0.9%
        transfer(charityAddress, charityAmount);
        transfer(holderIncentive, incentiveAmount);
        transfer(marketingDevAddress, marketingDevAmount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!blacklist[_msgSender()], "Sender is blacklisted");
        require(!blacklist[recipient], "Recipient is blacklisted");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(!blacklist[sender], "Sender is blacklisted");
        require(!blacklist[recipient], "Recipient is blacklisted");
        return super.transferFrom(sender, recipient, amount);
    }

    function addToBlacklist(address _addr) public onlyOwner {
        blacklist[_addr] = true;
    }

    function removeFromBlacklist(address _addr) public onlyOwner {
        blacklist[_addr] = false;
    }
}
