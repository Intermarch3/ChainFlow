// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TestContract} from "../src/Counter.sol";

contract CounterTest is Test {
    TestContract public c;

    function setUp() public {
        c = new TestContract();
    }

    function test_SendMoney() public {
        vm.deal(address(c), 2 ether);
        c.sendMoney(1 ether, payable(address(this)));
        assertEq(address(c).balance, 1 ether);
    }

    function test_Init() public {
        assertEq(c.init(), 1);
    }

    receive() external payable {}
}
