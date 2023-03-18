// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/BetEscrow.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./MockERC20.sol";
import "./MockChainlinkFeed.sol";

// The plan, according to ChatGPT4:
//
// 1. Test the constructor:
//  - Check that the contract state is Collecting when oracle data is valid.
//  - Check that the contract state is Failed when oracle data is invalid or older than a day.
//
// 2. Test USDC and WBTC deposits:
//  - Check that bettorA can deposit the required USDC amount.
//  - Check that bettorB can deposit the required WBTC amount.
//  - Check that deposits update the contract state to Locked when both deposits are complete.
//  - Check that deposits are rejected when the contract is in the wrong state.
//
// 3. Test the fail function:
//  - Check that the contract state changes to Failed if called after the deadline and still in Collecting state.
//  - Check that the function is rejected if called before the deadline or in the wrong state.
//
// 4. Test withdrawals in the Failed state:
//  - Check that bettorA can withdraw the USDC balance.
//  - Check that bettorB can withdraw the WBTC balance.
//  - Check that withdrawals are rejected when the contract is in the wrong state.
//
// 5. Test the settle function:
//  - Check that the function is rejected if the contract is in the wrong state.
//  - Check that the function is rejected if called before the settlement date.
//  - Check that the function is rejected if the oracle data is invalid or too old.
//  - Check that the winner is correctly determined and receives both the USDC and WBTC balances.
//  - Check that the contract state changes to Settled after a successful settlement.
contract BetEscrowTest is Test {
    // Bettor addresses
    address payable bettorA = payable(address(0x41));
    address payable bettorB = payable(address(0x42));

    // Set up oracle data and tokens for testing
    MockChainlinkFeed feed = new MockChainlinkFeed(100, block.timestamp);
    MockERC20 usdc = new MockERC20();
    MockERC20 wbtc = new MockERC20();

    address aFeed = address(feed);
    address aUsdc = address(usdc);
    address aWbtc = address(wbtc);

    function testConstructor() public {
        // Test when oracle data is valid
        BetEscrow be1 = new BetEscrow(bettorA, bettorB, aFeed, aUsdc, aWbtc);
        assertEq(uint(be1.state()), uint(BetEscrow.ContractState.Collecting));

        // Test when oracle data is invalid
        feed.setPrice(0);
        vm.expectRevert("Invalid oracle data");
        new BetEscrow(bettorA, bettorB, aFeed, aUsdc, aWbtc);
    }

    function testDeposits() public {
        // Set up valid oracle data and addresses for testing
        BetEscrow be = new BetEscrow(bettorA, bettorB, aFeed, aUsdc, aWbtc);

        // Test depositing USDC and WBTC
        usdc.mint(bettorA, 1e6 * 1e6);
        vm.prank(bettorA);
        usdc.transfer(address(be), 1e6 * 1e6);
        assertEq(uint(be.state()), uint(BetEscrow.ContractState.Collecting));

        wbtc.mint(bettorB, 1e8);
        vm.prank(bettorB);
        wbtc.transfer(address(be), 1e8);
        assertEq(uint(be.state()), uint(BetEscrow.ContractState.Collecting));

        // Once both deposits complete, either party can call lockDeposits().
        vm.prank(bettorA);
        be.lockDeposits();
        assertEq(uint(be.state()), uint(BetEscrow.ContractState.Locked));
    }

    function testFailFunction() public {
        // Set up valid oracle data and addresses for testing
        BetEscrow be = new BetEscrow(bettorA, bettorB, aFeed, aUsdc, aWbtc);

        // Deposit correct WBTC, insufficient USDC
        usdc.mint(address(be), 900000 * 1e6);
        wbtc.mint(address(be), 1e8);
        be.lockDeposits();
        assertEq(uint(be.state()), uint(BetEscrow.ContractState.Locked));

        // Test rejecting fail function before the deadline
        vm.expectRevert("Deadline not reached yet");
        be.fail();

        uint256 start = block.timestamp;
        vm.warp(start + 6 days);
        vm.expectRevert("Deadline not reached yet");
        be.fail();

        // Test changing contract state to Failed
        vm.warp(start + 7 days);
        be.fail();
        assertEq(uint(be.state()), uint(BetEscrow.ContractState.Failed));

        // Make sure both bettors got their money back
        assertEq(usdc.balanceOf(bettorA), 900000 * 1e6);
        assertEq(wbtc.balanceOf(bettorB), 1e8);
    }

    function testSettleBettorAWins() public {
        // Set up valid oracle data and addresses for testing
        BetEscrow be = new BetEscrow(bettorA, bettorB, aFeed, aUsdc, aWbtc);

        // Test rejecting settle function in wrong state
        vm.expectRevert("Wrong state");
        be.settle();

        // Deposit correct WBTC and USDC
        usdc.mint(address(be), 1e6 * 1e6);
        wbtc.mint(address(be), 1e8);
        be.lockDeposits();
        assertEq(uint(be.state()), uint(BetEscrow.ContractState.Locked));

        // Test rejecting fail function once deposits are locked
        vm.expectRevert("Wrong state");
        be.fail();

        // Test rejecting settle function before settlement date
        vm.expectRevert("Settlement date not reached yet");
        be.settle();
        uint start = block.timestamp;
        vm.warp(start + 89 days);
        vm.expectRevert("Settlement date not reached yet");
        be.settle();

        // Test rejecting settle function if oracle data is invalid or too old
        vm.warp(start + 90 days);
        vm.expectRevert("Oracle data too old");
        be.settle();

        // Test winner determination and asset transfers
        feed.setPrice(150);
        be.settle();
        assertEq(uint(be.state()), uint(BetEscrow.ContractState.Settled));

        // Price hasn't doubled, so bettorB should win
        assertEq(usdc.balanceOf(bettorA), 0);
        assertEq(wbtc.balanceOf(bettorA), 0);
        assertEq(usdc.balanceOf(bettorB), 1e6 * 1e6);
        assertEq(wbtc.balanceOf(bettorB), 1e8);
    }

    function testSettleBettorBWins() public {
        // Starting price: 100
        BetEscrow be = new BetEscrow(bettorA, bettorB, aFeed, aUsdc, aWbtc);

        // Deposit and lock WBTC and USDC
        usdc.mint(address(be), 1e6 * 1e6);
        wbtc.mint(address(be), 1e8);
        be.lockDeposits();
        assertEq(uint(be.state()), uint(BetEscrow.ContractState.Locked));

        // Warp to the end. Price has doubled, so bettorA should win
        vm.warp(block.timestamp + 90 days);
        feed.setPrice(201);
        be.settle();
        assertEq(uint(be.state()), uint(BetEscrow.ContractState.Settled));

        // Price has doubled, so bettorA should win
        assertEq(usdc.balanceOf(bettorA), 1e6 * 1e6);
        assertEq(wbtc.balanceOf(bettorA), 1e8);
        assertEq(usdc.balanceOf(bettorB), 0);
        assertEq(wbtc.balanceOf(bettorB), 0);
    }
}
