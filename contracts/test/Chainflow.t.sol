// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ChainflowContract, ChainflowPayment} from "../src/Chainflow.sol";

contract ChainFlowTests is Test {
    ChainflowContract public CFContract;
    ChainflowPayment public CFPayment;

    function setUp() public {
        CFPayment = new ChainflowPayment();
        CFContract = new ChainflowContract(address(CFPayment), address(0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0));
    }

    function test_getPaymentContract() public view {
        assertEq(address(CFPayment), address(CFContract.getPaymentContract()));
    }

    function test_setPaymentContract() public {
        ChainflowPayment newPayment = new ChainflowPayment();
        CFContract.setPaymentContract(address(newPayment));
        assertEq(address(newPayment), address(CFContract.getPaymentContract()));
    }

    receive() external payable {}
}
