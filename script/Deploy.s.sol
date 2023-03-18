// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/BetEscrow.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        // Bettor A deposits 1m USDC, bettor B deposits 1 WBTC
        address bettorA = 0x823E0F5338061900BA7347E0aA1367BeD70Cf9F1; // balaji.eth
        address bettorB = 0x0; // TODO: counterparty

        // XAG/USD Chainlink feed, xag-usd.data.eth
        address priceFeedAddress = 0x379589227b15f1a12195d3f2d90bbc9f31f95235;
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address wbtc = 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599;

        vm.broadcast();
        new BetEscrow(betterA, bettorB, priceFeedAddress, usdc, wbtc);
    }
}
