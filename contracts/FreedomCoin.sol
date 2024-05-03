// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";
/*

Website: https://thefreedomcoin.org
Whitepaper: docs.thefreedomcoin.org
Instagram: https://www.instagram.com/_freedomcoin
X (Twitter): https://twitter.com/freedomcoinf
Telegram: https://t.me/freedomcoinether

**/

contract FreedomCoin is ERC20, Ownable, ERC20Permit {

    mapping (address => bool) public liquidityPools;

    address payable public charityAddress = payable(0x047c0D746D42fF4cEe7d2CB1FBf5c0D090267931);
    address payable public marketingDevAddress = payable(0x0331535b9f37EB41F437EA0cfE345ABB9d102A1A);

    address public uniswapV2RouterAddress = 0xedf6066a2b290C185783862C7F4776A2C8077AD1;
    IUniswapV2Router02 public uniswapV2Router;
    address public pairV2;

    uint16 public liquidityFee = 10;
    uint16 public charityFee = 10;
    uint16 public devMarketingFee = 9;
    bool public swapEnabled = false;


    constructor(address initialOwner)
        ERC20("Freedom Coin", "FREED")
        Ownable(initialOwner)
        ERC20Permit("Freedom")
    {
        uint256 totalSupply = 7000000 * (10 ** uint256(decimals()));
        _mint(initialOwner, totalSupply);
        uint256 charityAmount = totalSupply * 1 / 100; // 1%
        uint256 marketingDevAmount = totalSupply * 9 / 1000; // 0.9%

        transferFrom(initialOwner,charityAddress, charityAmount);
        transferFrom(initialOwner,marketingDevAddress, marketingDevAmount);
        uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);

        pairV2 = IUniswapV2Factory(uniswapV2Router.factory()).createPair(uniswapV2Router.WETH(), address(this));
        liquidityPools[pairV2] = true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function clearStuckBalance(uint256 amountPercentage, address adr) external onlyOwner() {
        uint256 amountETH = address(this).balance;

        if(amountETH > 0) {
            (bool sent, ) = adr.call{value: (amountETH * amountPercentage) / 100}("");
            require(sent,"Failed to transfer funds");
        }
    }

    function swapDisableOrEnable(bool _status) external onlyOwner {
        swapEnabled = _status;
    }

    function _transferWithFee(address sender, address recipient, uint256 amount) public {
        if (swapEnabled && (liquidityPools[sender] || liquidityPools[recipient])) {
            uint256 _calCharityFee = (amount * charityFee) / 1000;
            uint256 _calLiquidityFee = (amount * liquidityFee) / 1000;
            uint256 _calDevMarketingFee = (amount * devMarketingFee) / 1000;
            uint256 _calTotalFees = _calCharityFee + _calLiquidityFee + _calDevMarketingFee;
            uint256 amountAfterFees = amount - _calTotalFees;

            super._transfer(sender, address(this), _calTotalFees);
            super._transfer(sender, recipient, amountAfterFees);

            (uint256 amountOutCharity) = swapToETH(_calCharityFee);
            (uint256 amountOutMarketing) = swapToETH(_calDevMarketingFee);
            sendETHToWallet(charityAddress, amountOutCharity);
            sendETHToWallet(marketingDevAddress, amountOutMarketing);

            swapTokensForEthAndAddLiquidity(sender, _calLiquidityFee);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function sendETHToWallet(address payable _to, uint256 _amount) internal {
        // Sends _amount of Wei to address _to, and reverts if the transfer fails
        _to.transfer(_amount);
    }

    function swapToETH(uint256 _amount) internal returns(uint256 amountOut) {
        uint256 initialBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        require(balanceOf(address(this)) >= _amount, "Insufficient tokens in contract");

        _approve(address(this), address(uniswapV2RouterAddress), _amount);

        require(_amount <= allowance(address(this), address(uniswapV2Router)), "Swap request exceeds allowance");

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 600
        );
        amountOut = address(this).balance - initialBalance;
    }

    function swapTokensForEthAndAddLiquidity(address sender, uint256 tokenAmount) internal {
        (uint256 newBalance) = swapToETH(tokenAmount);
        require(newBalance > 0, "Swap to ETH failed, no ETH received");

        addLiquidityETH(tokenAmount, newBalance, sender);
    }

    function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount, address to) internal {
        require(address(this).balance >= ethAmount, "Not enough ETH for liquidity");
        _approve(address(this), address(uniswapV2RouterAddress), tokenAmount);
        require(tokenAmount <= allowance(address(this), address(uniswapV2Router)), "Liquidity addition request exceeds allowance");

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            to,
            block.timestamp + 600
        );
        
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        address sender = _msgSender();
        _transferWithFee(sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender,address recipient, uint256 amount) public virtual override returns (bool) {
        _transferWithFee(sender, recipient, amount);
        return true;
    }

    function addLiquidityPool(address _liquidityAddress, bool _isActive) public onlyOwner {
        liquidityPools[_liquidityAddress] = _isActive;
    }

    receive() external payable {}
}

