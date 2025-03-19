// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ChainflowContract, ChainflowPayment} from "../src/Chainflow.sol";

contract CFTest is Test {
    ChainflowContract public CF;
    ChainflowPayment public CP;

    function setUp() public {
        CP = new ChainflowPayment();
        CF = new ChainflowContract(address(CP));
    }

    function testNewSubscription() public {
        CF.newSubscription(address(0), 0, address(0), 0);
        uint256[] memory subs = CF.getMySubscriptions();
        CF.subscriptions(0);
        for (uint256 i = 0; i < subs.length; i++) {
            CF.getSubscription(subs[i]);
        }
    }

    receive() external payable {}
}
