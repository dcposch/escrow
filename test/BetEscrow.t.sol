// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/BetEscrowTest.sol";

// The plan, according to ChatGPT4:
//
// 1. Test the constructor:
//  - Check that the contract state is Collecting when oracle data is valid.
//  - Check that the contract state is Failed when oracle data is invalid or older than a day.
//
// 2. Test USDC and WBTC deposits:
//  - Check that bettorA can deposit the required USDC amount.
//  - Check that bettorB can deposit the required WBTC amount.
//  - Check that deposits update the contract state to Holding when both deposits are complete.
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
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function testConstructor() public {
        // Set up valid oracle data and addresses for testing
        // ...

        // Test when oracle data is valid
        BetEscrow be1 = new BetEscrow(
            bettorA,
            bettorB,
            priceFeedAddress,
            USDCAddress,
            WBTCAddress
        );
        assertEq(uint(be1.state()), uint(BetEscrow.ContractState.Collecting));

        // Test when oracle data is invalid
        // ...
        vm.expectRevert("Invalid oracle data");
        BetEscrow be2 = new BetEscrow(
            bettorA,
            bettorB,
            invalidPriceFeedAddress,
            USDCAddress,
            WBTCAddress
        );
    }

    function testDeposits() public {
        // Set up valid oracle data and addresses for testing
        // ...
        BetEscrow be = new BetEscrow(
            bettorA,
            bettorB,
            priceFeedAddress,
            USDCAddress,
            WBTCAddress
        );

        // Test depositing USDC and WBTC
        // ...
        assertEq(uint(be.state()), uint(BetEscrow.ContractState.Holding));

        // Test rejecting deposits in the wrong state
        // ...
    }

    function testFailFunction() public {
        // Set up valid oracle data and addresses for testing
        // ...
        BetEscrow be = new BetEscrow(
            bettorA,
            bettorB,
            priceFeedAddress,
            USDCAddress,
            WBTCAddress
        );

        // Test changing contract state to Failed
        // ...
        assertEq(uint(be.state()), uint(BetEscrow.ContractState.Failed));

        // Test rejecting fail function in the wrong state or before the deadline
        // ...
    }

    function testWithdrawalsInFailedState() public {
        // Set up valid oracle data and addresses for testing
        // ...
        BetEscrow be = new BetEscrow(
            bettorA,
            bettorB,
            priceFeedAddress,
            USDCAddress,
            WBTCAddress
        );

        // Test withdrawing USDC and WBTC
        // ...

        // Test rejecting withdrawals in the wrong state
        // ...
    }

    function testSettleFunction() public {
        // Set up valid oracle data and addresses for testing
        // ...
        BetEscrow be = new BetEscrow(
            bettorA,
            bettorB,
            priceFeedAddress,
            USDCAddress,
            WBTCAddress
        );

        // Test rejecting settle function in the wrong state or before settlement date
        // ...

        // Test rejecting settle function if oracle data is invalid or too old
        // ...

        // Test winner determination and asset transfers
        // ...

        // Test changing contract state to Settled
        // ...
    }
}
