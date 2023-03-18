// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// A simple escrow to settle Balaji and JC Medlock's bet about hyperinflation.
// Written almost entirely by GPT4.
contract BetEscrow {
    enum ContractState {
        Collecting,
        Locked,
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

        // Fetch oracle price. Ensure that it's valid and not too old.
        (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
        require(
            price > 0 && block.timestamp < updatedAt + 1 days,
            "Invalid oracle data"
        );
        startingPrice = uint256(price);

        state = ContractState.Collecting;
    }

    // Called after Bettor A has deposited USDC and Bettor B has deposited WBTC.
    // This locks in the bet until the settlement date.
    function lockDeposits() external {
        if (
            USDC.balanceOf(address(this)) >= 1e6 * 1e6 &&
            WBTC.balanceOf(address(this)) >= 1e8
        ) {
            state = ContractState.Locked;
        }
    }

    // Called if one of the parties fails to deposit timely, by the other party.
    function fail() external {
        require(state == ContractState.Collecting, "Wrong state");
        require(block.timestamp > deadline, "Deadline not reached yet");
        state = ContractState.Failed;

        uint256 amountA = USDC.balanceOf(address(this));
        USDC.transfer(bettorA, amountA);

        uint256 amountB = WBTC.balanceOf(address(this));
        WBTC.transfer(bettorB, amountB);
    }

    // Called by the victor, after the settlement date has passed.
    function settle() external {
        require(state == ContractState.Locked, "Wrong state");
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
