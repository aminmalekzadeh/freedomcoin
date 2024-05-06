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
    mapping (address => bool) private _isExcludedFromFee;

    address payable public charityAddress = payable(0x5938c0BA9e593f631D682B0c35e6883eB65B108D);
    address payable public marketingDevAddress = payable(0x0331535b9f37EB41F437EA0cfE345ABB9d102A1A);

    //address public uniswapV2RouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // MAINNET
    address public uniswapV2RouterAddress = 0xedf6066a2b290C185783862C7F4776A2C8077AD1; // POLYGON
    IUniswapV2Router02 public uniswapV2Router;
    address public pairV2;

    uint16 public liquidityFee = 10;
    uint16 public charityFee = 10;
    uint16 public devMarketingFee = 9;
    uint256 public swapTokensAtAmount = 10000 * 10 ** decimals(); // Minimum tokens required for swap

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    uint256 private _tempCharityFee = 0;
    uint256 private _tempMarketingFee = 0;
    uint256 private _tempLiquidityFee = 0;

    constructor(address initialOwner)
        ERC20("Freedom Coin", "FREED")
        Ownable(initialOwner)
        ERC20Permit("Freedom")
    {
        uint256 totalSupply = 7000000 * (10 ** decimals());
        _mint(initialOwner, totalSupply);
        // Direct transfers to predefined addresses
        transfer(charityAddress, totalSupply * 1 / 100); // 1%
        transfer(marketingDevAddress, totalSupply * 9 / 1000); // 0.9%

        uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);

        pairV2 = IUniswapV2Factory(uniswapV2Router.factory()).createPair(uniswapV2Router.WETH(), address(this));
        require(pairV2 != address(0), "Failed to create pair");
        liquidityPools[pairV2] = true;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingDevAddress] = true;
        _isExcludedFromFee[charityAddress] = true;

        _approve(address(this), uniswapV2RouterAddress, type(uint256).max);
    }

    function clearStuckNativeBalance(uint256 amountPercentage, address adr) external onlyOwner() {
        uint256 amountETH = address(this).balance;

        if(amountETH > 0) {
            (bool sent, ) = adr.call{value: (amountETH * amountPercentage) / 100}("");
            require(sent,"Failed to transfer funds");
        }
    }

    function swapForETHToUniswapV2(uint256 _amount, address _to, bool _needAddliquidity) public onlyOwner {
        swapToETH(_amount);
        if(_needAddliquidity){
            swapAndLiquify(_amount);
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function _transferWithFee(address sender, address recipient, uint256 amount) public {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        _tempCharityFee = (amount * charityFee) / 1000;  // Multiplication followed by division
        _tempLiquidityFee = (amount * liquidityFee) / 1000;
        _tempMarketingFee = (amount * devMarketingFee) / 1000;
        uint256 _calTotalFees = _tempCharityFee + _tempLiquidityFee + _tempMarketingFee;
        uint256 amountAfterFees = amount - _calTotalFees;

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;

        if (!inSwap && sender != pairV2 && sender != owner() && recipient != owner() && canSwap) {
           swapBack();
        }
        bool takeFee = !inSwap;

        if(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]){
            takeFee = false;
        }

        if(!liquidityPools[sender] || !liquidityPools[recipient]){
            takeFee = false;
        }

        if(takeFee){
            super._transfer(sender, address(this), _calTotalFees);
            super._transfer(sender, recipient, amountAfterFees);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function swapBack() internal swapping {
        if(_tempCharityFee > 0){
            (uint256 amountOut) = swapToETH(_tempCharityFee);
            sendETHToWallet(charityAddress, amountOut);
            _tempCharityFee = 0;
        } 
        if(_tempMarketingFee > 0){
           (uint256 amountOut) = swapToETH(_tempMarketingFee);
            sendETHToWallet(charityAddress, amountOut);
            _tempMarketingFee = 0;
        }
        if(_tempLiquidityFee > 0){
            swapAndLiquify(_tempLiquidityFee / 2);
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
        require(_amount <= allowance(address(this), address(uniswapV2RouterAddress)), "Swap request exceeds allowance");

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0, // accept any amount of ETH
            path,
            address(this),
            (block.timestamp)
        );
        amountOut = address(this).balance - initialBalance;
    }

    function swapAndLiquify(uint256 tokenAmount) internal {
        (uint256 newBalance) = swapToETH(tokenAmount);
        require(newBalance > 0, "Swap to ETH failed, no ETH received");

        _addLiquidityETH(tokenAmount, newBalance);
    }

    function depositTokens(uint256 amount) public {
        // Update the balance in storage
        _transfer(msg.sender, address(this), amount);
    }

function _addLiquidityETH(uint256 tokenAmount, uint256 ethAmount) internal {
    require(address(this).balance >= ethAmount, "Not enough ETH for liquidity");
    _approve(address(this), address(uniswapV2RouterAddress), tokenAmount);

    require(tokenAmount <= allowance(address(this), address(uniswapV2Router)), "Liquidity addition request exceeds allowance");

    // Add liquidity and capture the results to validate them
    (uint256 tokenAmountSent, uint256 ethAmountSent, uint256 liquidity) = uniswapV2Router.addLiquidityETH{value: ethAmount}(
        address(this),
        tokenAmount,
        0,
        0,
        address(this),
        block.timestamp + 600
    );

    // Ensure that liquidity tokens were issued
    require(liquidity > 0, "Liquidity addition failed");
    // Optional: Validate the amounts sent to the pool
    require(tokenAmountSent == tokenAmount && ethAmountSent == ethAmount, "Mismatch in expected liquidity amounts");

    _tempLiquidityFee = 0;
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

