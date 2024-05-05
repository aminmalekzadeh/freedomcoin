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

    //address public uniswapV2RouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // MAINNET
    address public uniswapV2RouterAddress = 0xedf6066a2b290C185783862C7F4776A2C8077AD1; // POLYGON
    IUniswapV2Router02 public uniswapV2Router;
    address public pairV2;

    uint16 public liquidityFee = 10;
    uint16 public charityFee = 10;
    uint16 public devMarketingFee = 9;

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
    }

   function initializeUniswapInteractions(address _uniswapRouterAddress) external onlyOwner {
    require(_uniswapRouterAddress != address(0), "Invalid router address");
    uniswapV2RouterAddress = _uniswapRouterAddress;
    uniswapV2Router = IUniswapV2Router02(_uniswapRouterAddress);

    // Create a trading pair on Uniswap
    pairV2 = IUniswapV2Factory(uniswapV2Router.factory()).createPair(uniswapV2Router.WETH(), address(this));
    require(pairV2 != address(0), "Failed to create pair");
    liquidityPools[pairV2] = true;

    // Approve the Uniswap router to handle tokens for adding liquidity
    _approve(address(this), _uniswapRouterAddress, type(uint256).max);
}

    function clearStuckNativeBalance(uint256 amountPercentage, address adr) external onlyOwner() {
        uint256 amountETH = address(this).balance;

        if(amountETH > 0) {
            (bool sent, ) = adr.call{value: (amountETH * amountPercentage) / 100}("");
            require(sent,"Failed to transfer funds");
        }
    }

    function swapForETHToUniswapV2(uint256 _amount, address _to, bool _needAddliquidity) public onlyOwner {
        swapToETH(_amount, _to);
        if(_needAddliquidity){
            swapAndLiquify(_amount);
        }
    }

function _transferWithFee(address sender, address recipient, uint256 amount) public {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    uint256 taxAmount = 0;
    _tempCharityFee = (amount * charityFee) / 1000;  // Multiplication followed by division
    _tempLiquidityFee = (amount * liquidityFee) / 1000;
    _tempMarketingFee = (amount * devMarketingFee) / 1000;
    uint256 _calTotalFees = _tempCharityFee + _tempLiquidityFee + _tempMarketingFee;
    uint256 amountAfterFees = amount - _calTotalFees;

    if (inSwap) {             
        super._transfer(sender, recipient, amount);
        return;
    }

    if (liquidityPools[recipient] || liquidityPools[sender]) {
        taxAmount = _calTotalFees;
        super._transfer(sender, address(this), _calTotalFees);
    }

    super._transfer(sender, recipient, amountAfterFees);

    if (taxAmount > 0) {
        swapBack();
    }
}

    function swapBack() internal swapping {
        if(_tempCharityFee > 0){
            swapToETH(_tempCharityFee / 2, charityAddress);
            _tempCharityFee = 0;
        } 
        if(_tempMarketingFee > 0){
            swapToETH(_tempMarketingFee / 2, marketingDevAddress);
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

    function swapToETH(uint256 _amount, address _to) internal returns(uint256 amountOut) {
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
            _to,
            (block.timestamp)
        );
        amountOut = address(this).balance - initialBalance;
    }

    function swapAndLiquify(uint256 tokenAmount) internal {
        (uint256 newBalance) = swapToETH(tokenAmount, address(this));
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
        0, // slippage is unavoidable
        0, // slippage is unavoidable
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

