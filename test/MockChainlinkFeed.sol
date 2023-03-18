// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Mock chainlink feed, written entirely by GPT4
contract MockChainlinkFeed is AggregatorV3Interface {
    int256 private _price;
    uint256 private _timestamp;

    constructor(int256 initialPrice, uint256 initialTimestamp) {
        _price = initialPrice;
        _timestamp = initialTimestamp;
    }

    function latestRoundData()
        public
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (0, _price, 0, _timestamp, 0);
    }

    function setPrice(int256 newPrice) public {
        _price = newPrice;
        _timestamp = block.timestamp;
    }

    // Other AggregatorV3Interface functions that revert

    function decimals() external pure override returns (uint8) {
        revert("Not implemented");
    }

    function description() external pure override returns (string memory) {
        revert("Not implemented");
    }

    function version() external pure override returns (uint256) {
        revert("Not implemented");
    }

    function getRoundData(
        uint80
    )
        external
        pure
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        revert("Not implemented");
    }
}
