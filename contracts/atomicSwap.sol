// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./univ2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./univ2-core/contracts/interfaces/IERC20.sol";

interface IWeth {
    function withdraw(uint256 wad) external;
}

contract AtomicSwap {
    address public WETH;

    constructor(address weth) {
        WETH = weth;
    }

    // perform swap and keep resulting token balance in contract
    function swap(
        uint256 amount0Out, // param to pair.swap
        uint256 amount1Out, // param to pair.swap
        uint256 amountIn, // amount of tokens that searcher sends to swap
        address tokenInAddress, // address of token that searcher sends to swap
        address pairAddress // univ2 pair address to execute swap
    ) public {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        IERC20 tokenIn = IERC20(tokenInAddress);
        require(
            tokenIn.transferFrom(msg.sender, pairAddress, amountIn),
            "transfer failed"
        );
        pair.swap(amount0Out, amount1Out, address(this), "");
    }

    // assume we only settle in WETH
    function bribeSwap(
        uint256 amount0Out, // param to pair.swap
        uint256 amount1Out, // param to pair.swap
        uint256 amountIn, // amount of tokens that searcher sends to swap
        address tokenInAddress, // address of token that searcher sends to swap
        address pairAddress // univ2 pair address to execute swap
    ) public {
        IERC20 tokenOut = IERC20(WETH);
        uint256 startBalance = tokenOut.balanceOf(address(this));
        swap(amount0Out, amount1Out, amountIn, tokenInAddress, pairAddress);
        uint256 endBalance = tokenOut.balanceOf(address(this));
        require(endBalance > startBalance, "arb was not profitable");
        uint256 bribeAmount = ((endBalance - startBalance) * 90) / 100; // bribe 90%
        // tokenOut.transferFrom(address(this), block.coinbase, value); // don't transfer tokens to coinbase, transfer ETH
        IWeth weth = IWeth(WETH);
        weth.withdraw(bribeAmount);
        block.coinbase.transfer(bribeAmount);
    }
}
