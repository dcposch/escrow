// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BetEscrow {
    enum ContractState {
        Collecting,
        Holding,
        Settled,
        Failed
    }

    address payable public bettorA;
    address payable public bettorB;
    uint256 public deadline;
    uint256 public settlementDate;
    uint256 public startingPrice;
    ContractState public state;

    IERC20 public USDC;
    IERC20 public WBTC;
    AggregatorV3Interface public priceFeed;

    constructor(
        address payable _bettorA,
        address payable _bettorB,
        address _priceFeedAddress,
        address _USDCAddress,
        address _WBTCAddress
    ) {
        bettorA = _bettorA;
        bettorB = _bettorB;
        deadline = block.timestamp + 7 days;
        settlementDate = block.timestamp + 90 days;

        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        USDC = IERC20(_USDCAddress);
        WBTC = IERC20(_WBTCAddress);

        (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
        if (price < 0 || block.timestamp > updatedAt + 1 days) {
            state = ContractState.Failed;
        } else {
            startingPrice = uint256(price);
            state = ContractState.Collecting;
        }
    }

    function depositUSDC() external {
        require(state == ContractState.Collecting, "Wrong state");
        require(msg.sender == bettorA, "Only bettor A can deposit USDC");
        uint256 amount = 1e6 * 1e6; // 1 million USDC (assuming 6 decimals)
        USDC.transferFrom(msg.sender, address(this), amount);
        checkHoldingState();
    }

    function depositWBTC() external {
        require(state == ContractState.Collecting, "Wrong state");
        require(msg.sender == bettorB, "Only bettor B can deposit WBTC");
        uint256 amount = 1e8; // 1 WBTC (assuming 8 decimals)
        WBTC.transferFrom(msg.sender, address(this), amount);
        checkHoldingState();
    }

    function checkHoldingState() internal {
        if (
            USDC.balanceOf(address(this)) >= 1e6 * 1e6 &&
            WBTC.balanceOf(address(this)) >= 1e8
        ) {
            state = ContractState.Holding;
        }
    }

    function fail() external {
        require(state == ContractState.Collecting, "Wrong state");
        require(block.timestamp > deadline, "Deadline not reached yet");
        state = ContractState.Failed;
    }

    function withdrawUSDC() external {
        require(state == ContractState.Failed, "Wrong state");
        require(msg.sender == bettorA, "Only bettor A can withdraw USDC");
        uint256 amount = USDC.balanceOf(address(this));
        USDC.transfer(bettorA, amount);
    }

    function withdrawWBTC() external {
        require(state == ContractState.Failed, "Wrong state");
        require(msg.sender == bettorB, "Only bettor B can withdraw WBTC");
        uint256 amount = WBTC.balanceOf(address(this));
        WBTC.transfer(bettorB, amount);
    }

    function settle() external {
        require(state == ContractState.Holding, "Wrong state");
        require(
            block.timestamp >= settlementDate,
            "Settlement date not reached yet"
        );

        (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
        require(price >= 0, "Invalid price data");
        require(updatedAt >= settlementDate, "Oracle data too old");

        uint256 currentPrice = uint256(price);

        address payable winner;

        if (currentPrice > 2 * startingPrice) {
            winner = bettorA;
        } else {
            winner = bettorB;
        }

        // Transfer all USDC and WBTC to the winner
        uint256 USDCBalance = USDC.balanceOf(address(this));
        uint256 WBTCBalance = WBTC.balanceOf(address(this));

        USDC.transfer(winner, USDCBalance);
        WBTC.transfer(winner, WBTCBalance);

        state = ContractState.Settled;
    }
}
