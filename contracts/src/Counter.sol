// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract TestContract {
    uint256 public count;
    function sendMoney(uint256 amount, address payable to) public {
        to.transfer(amount);
    }

    function init() public pure returns (uint256) {
        return 1;
    }

    function init2() public {
        count = count + 1;
    }
}
