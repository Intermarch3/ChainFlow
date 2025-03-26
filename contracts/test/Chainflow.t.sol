// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ChainflowContract, ChainflowPayment} from "../src/Chainflow.sol";

contract ChainFlowTests is Test {
    ChainflowContract public CFContract;
    ChainflowPayment public CFPayment;

    function setUp() public {
        CFPayment = new ChainflowPayment();
        CFContract = new ChainflowContract(payable(address(CFPayment)), address(0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976), address(0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad), address(0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9));
    }

    function test_getPaymentContract() public view {
        assertEq(address(CFPayment), address(CFContract.getPaymentContract()));
    }

    receive() external payable {}
}
