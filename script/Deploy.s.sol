// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/BetEscrow.sol";

contract Deploy is Script {
    function setUp() public {}

    function run() public {
        // Bettor A deposits 1m USDC, bettor B deposits 1 WBTC
        // balaji.eth
        address payable bettorA = payable(
            0x823E0F5338061900BA7347E0aA1367BeD70Cf9F1
        );
        // TODO: counterparty
        address payable bettorB = payable(
            0x0000000000000000000000000000000000000001
        );

        // XAG/USD Chainlink feed, xag-usd.data.eth
        address priceFeedAddress = 0x379589227b15F1a12195D3f2d90bBc9F31f95235;
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

        vm.broadcast();
        new BetEscrow(bettorA, bettorB, priceFeedAddress, usdc, wbtc);
    }
}
