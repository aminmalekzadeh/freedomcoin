// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract FreedomCoin is ERC20, ERC20Permit, ERC20Votes, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    
    EnumerableSet.AddressSet private _whitelist;
    EnumerableSet.AddressSet private _blacklist;

    constructor(address initialOwner)
        ERC20("FreedomCoin", "FREED")
        ERC20Permit("FreedomCoin")
        Ownable(initialOwner)
    {
        transferOwnership(initialOwner);
        _mint(msg.sender, 7000000 * 10 ** decimals());
    }

    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, ERC20Permit)
        returns (uint256)
    {
        return super.nonces(owner);
    }

    // Whitelist and Blacklist functions

    function addToWhitelist(address account) public onlyOwner {
        require(!_whitelist.contains(account), "Account is already whitelisted");
        _whitelist.add(account);
    }

    function removeFromWhitelist(address account) public onlyOwner {
        require(_whitelist.contains(account), "Account not whitelisted");
        _whitelist.remove(account);
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist.contains(account);
    }

    function addToBlacklist(address account) public onlyOwner {
        require(!_blacklist.contains(account), "Account is already blacklisted");
        _blacklist.add(account);
    }

    function removeFromBlacklist(address account) public onlyOwner {
        require(_blacklist.contains(account), "Account not blacklisted");
        _blacklist.remove(account);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist.contains(account);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);

        require(!isBlacklisted(from), "Sender is blacklisted");
        require(!isBlacklisted(to), "Recipient is blacklisted");
        require(isWhitelisted(to) || to == address(0), "Recipient is not whitelisted");
    }
}
