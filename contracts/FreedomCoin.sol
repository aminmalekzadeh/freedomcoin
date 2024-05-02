// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
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


contract FreedomCoin is ERC20, Ownable {

    address public constant charityAddress = 0x047c0D746D42fF4cEe7d2CB1FBf5c0D090267931;
    address public constant marketingDevAddress = 0x0331535b9f37EB41F437EA0cfE345ABB9d102A1A;
    address public pairV2;
    address public uniswapV2RouterAddress = 0xedf6066a2b290C185783862C7F4776A2C8077AD1;
    uint16 public liquidityFee = 100;
    mapping (address => bool) liquidityPools;
    IUniswapV2Router02 public uniswapV2Router;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }


    constructor(address initialOwner)
        ERC20("Freedom Coin", "FREED")
        Ownable(initialOwner)
    {
        uint256 totalSupply = 7000000 * (10 ** uint256(decimals()));
        _mint(address(this), totalSupply);  // Mint all tokens to initial owner

        // Calculate amounts to be transferred to charity and marketing
        uint256 charityAmount = totalSupply * 1 / 100; // 1%
        uint256 marketingDevAmount = totalSupply * 9 / 1000; // 0.9%

        // Transfer tokens directly from initial owner to respective addresses
        transfer(charityAddress, charityAmount);
        transfer(marketingDevAddress, marketingDevAmount);
        transfer(initialOwner, totalSupply - (charityAmount + marketingDevAmount));

        uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);

        // Set up Uniswap router and pair automatically
        pairV2 = IUniswapV2Factory(uniswapV2Router.factory()).createPair(uniswapV2Router.WETH(), address(this));
        liquidityPools[pairV2] = true;
    }

   function transfer(address recipient, uint256 amount) public override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

   function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        return _transferFrom(sender, recipient, amount);
    } 

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);


        if(inSwap){ return super.transferFrom(sender, recipient, amount); }

        if (shouldTakeFee(sender, recipient)) {
            uint256 liquidityAmount = amount * 1 / liquidityFee;
            uint256 sendAmount = amount - liquidityAmount;
            super.transferFrom(sender, recipient, sendAmount);
            swapBack(liquidityAmount);
        } else {
            super.transferFrom(sender, recipient, amount);
        }
        
        return true;
    }

    function shouldTakeFee(address sender, address recipient) public view returns (bool) {
        return liquidityPools[sender] || liquidityPools[recipient];
    }

    function addLiquidityPool(address _liquidityAddress, bool _isActive) public onlyOwner returns(bool) {
        liquidityPools[_liquidityAddress] = _isActive;
        return true;
    }

    function swapBack(uint256 _amountToSwap) internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256 balanceBefore = address(this).balance;
        super._approve(address(this), address(uniswapV2RouterAddress), _amountToSwap);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance - balanceBefore;

        uniswapV2Router.addLiquidityETH{value: amountETH}(
                address(this),
                amountETH,
                0,
                0,
                address(pairV2),
                block.timestamp
        );
    }

    receive() external payable {}
}
