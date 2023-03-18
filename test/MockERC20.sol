// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// Mock token for unit testing, written entirely by GPT4
contract MockERC20 is IERC20 {
    mapping(address => uint256) private _balances;

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function mint(address recipient, uint256 amount) public {
        _balances[recipient] += amount;
        emit Transfer(address(0), recipient, amount);
    }

    // Other IERC20 functions that revert

    function totalSupply() public pure override returns (uint256) {
        revert("Not implemented");
    }

    function allowance(
        address,
        address
    ) public pure override returns (uint256) {
        revert("Not implemented");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("Not implemented");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert("Not implemented");
    }
}
