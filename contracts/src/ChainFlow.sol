// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ChainflowContract {
    address public owner;
    ChainflowPayment public paymentContract;
    struct Subscription {
        bool active;
        uint256 timePadding;
        uint256 lastPayment;
        address token;
        uint256 amount;
        address to;
        address from;
        uint256 taskId;
    }
    Subscription[] public subscriptions;
    mapping(address => uint256) public userNbSubs;

    constructor(address _paymentContract) {
        owner = msg.sender;
        paymentContract = ChainflowPayment(_paymentContract);
    }

    function setPaymentContract(address _paymentContract) public {
        require(msg.sender == owner, "Only owner can set payment contract");
        paymentContract = ChainflowPayment(_paymentContract);
    }

    function getPaymentContract() public view returns (address) {
        return address(paymentContract);
    }

    function newsubscription(
        address token,
        uint256 amount,
        address to,
        uint256 timePadding
    ) public {
        Subscription memory sub;
        sub.active = true;
        sub.timePadding = timePadding;
        sub.lastPayment = block.timestamp;
        sub.token = token;
        sub.amount = amount;
        sub.to = to;
        sub.from = msg.sender;
        subscriptions.push(sub);
        userNbSubs[msg.sender]++;

        // create gelato task
    }

    function getMySubscriptions() public view returns (uint256[] memory) {
        uint256[] memory mySubs = new uint256[](userNbSubs[msg.sender]);
        uint8 j = 0;

        for (uint256 i = 0; i < subscriptions.length; i++) {
            if (subscriptions[i].from == msg.sender) {
                mySubs[j] = i;
                j++;
            }
        }
        return mySubs;
    }

    function getSubscription(uint256 index) public view returns (Subscription memory) {
        require(subscriptions.length < index, "Index out of bounds");
        require(subscriptions[index].from == msg.sender, "You are not the owner of this subscription");
        return subscriptions[index];
    }
}


contract ChainflowPayment {
    bytes32 private constant DEDICATED_ADDR_SLOT = bytes32(uint256(keccak256("dedicatedMsgSender")) - 1);

    modifier onlyDedicatedMsgSender() {
        address dedicatedMsgSender;
        bytes32 slot = DEDICATED_ADDR_SLOT;
        assembly {
            dedicatedMsgSender := sload(slot)
        }
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    function setDedicatedMsgSender(address dedicatedMsgSender) public {
        require(msg.sender == address(this), "Only EOA Owner can set its own dedicatedMsgSender"); // IS THIS WORKING?
        bytes32 slot = DEDICATED_ADDR_SLOT;
        assembly {
            sstore(slot, dedicatedMsgSender)
        }
    }

    function sendETH(uint256 amount, address payable to) public onlyDedicatedMsgSender() {
        to.transfer(amount);
    }

    function sendERC20(
        address token,
        uint256 amount,
        address to
    ) public onlyDedicatedMsgSender() {
        IERC20(token).transfer(to, amount);
    }
}
