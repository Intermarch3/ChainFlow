// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AutomateTaskCreator} from "../lib/automate/contracts/integrations/AutomateTaskCreator.sol";
import "../lib/automate/contracts/integrations/Types.sol";

contract ChainflowContract is AutomateTaskCreator {
    struct Subscription {
        bool active;
        uint256 interval;
        address token;
        uint256 amount;
        address to;
        address from;
        bytes32 taskId;
    }

    address public owner;
    ChainflowPayment public paymentContract;
    Subscription[] public subscriptions;
    mapping(address => uint256) public userNbSubs;

    constructor(address _paymentContract, address _automate) AutomateTaskCreator(_automate, address(this)) {
        owner = msg.sender;
        paymentContract = ChainflowPayment(_paymentContract);
    }

    receive() external payable {}

    // change paymentContract implementation address
    function setPaymentContract(address _paymentContract) public {
        require(msg.sender == owner, "Only owner can set payment contract");
        paymentContract = ChainflowPayment(_paymentContract);
    }

    // create a subscription
    function newSubscription(
        address token,
        uint256 amount,
        address to,
        uint256 start,
        uint256 interval
    ) public returns(bytes32) {
        Subscription memory sub;
        sub.active = true;
        sub.interval = interval;
        sub.token = token;
        sub.amount = amount;
        sub.to = to;
        sub.from = msg.sender;
        sub.taskId = _createGelatoTask(sub, start);
        subscriptions.push(sub);
        userNbSubs[msg.sender]++;
        return sub.taskId;
    }

    // cancel a subscription
    function cancelSubscription(uint256 index) public {
        require(subscriptions.length >index, "Index out of bounds");
        require(subscriptions[index].from == msg.sender,
            "You are not the owner of this subscription");
        subscriptions[index].active = false;
        _cancelTask(subscriptions[index].taskId);
        userNbSubs[msg.sender]--;
    }

    // function called by gelato for a subscription payment
    function gelatoCallback(
        uint256 index
    ) public onlyDedicatedMsgSender() {
        Subscription memory sub = getSubscription(index);
        ChainflowPayment(sub.from).sendToken(sub.token, sub.amount, payable(address(sub.to)));

        // pay gelato fee
        (uint256 fee, address feeToken) = _getFeeDetails();
        if (fee == 0) return;
        ChainflowPayment(sub.from).sendToken(feeToken, fee, payable(address(this)));
        _transfer(fee, feeToken);
    }

    // get implementation address
    function getPaymentContract() public view returns (address) {
        return address(paymentContract);
    }

    // get list of index for each subscriptions msg.sender have
    function getMySubscriptions() public view returns (uint256[] memory) {
        uint256[] memory mySubs = new uint256[](userNbSubs[msg.sender]);
        uint8 j = 0;

        for (uint256 i = 0; i < subscriptions.length; i++) {
            if (subscriptions[i].from == msg.sender && subscriptions[i].active) {
                mySubs[j] = i;
                j++;
            }
        }
        return mySubs;
    }

    // get subscriptions infos from his index
    function getSubscription(uint256 index) public view returns (Subscription memory) {
        require(subscriptions.length > index, "Index out of bounds");
        require(subscriptions[index].from == msg.sender,
            "You are not the owner of this subscription");
        return subscriptions[index];
    }

    // create the gelato automate transaction
    function _createGelatoTask(Subscription memory sub, uint256 start) internal returns (bytes32) {
        bytes memory data = abi.encodeWithSelector(
            this.gelatoCallback.selector,
            subscriptions.length
        );
        ModuleData memory moduleData = ModuleData({
            modules: new Module[](2),
            args: new bytes[](2)
        });

        moduleData.modules[0] = Module.PROXY;
        moduleData.modules[1] = Module.TIME;
        moduleData.args[0] = _proxyModuleArg();
        moduleData.args[1] = _timeModuleArg(start, sub.interval);
        return _createTask(
            address(this),
            data,
            moduleData,
            address(0)
        );
    }
}


contract ChainflowPayment {
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    bytes32 private constant _DEDICATED_ADDR_SLOT = 
        bytes32(uint256(keccak256("dedicatedMsgSender")) - 1);

    modifier onlyDedicatedMsgSender() {
        address dedicatedMsgSender;
        bytes32 slot = _DEDICATED_ADDR_SLOT;
        assembly {
            dedicatedMsgSender := sload(slot)
        }
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    // change dedicatedMsgSender (address who can enable payment)
    function setDedicatedMsgSender(address dedicatedMsgSender) public {
        require(msg.sender == address(this),
            "Only EOA Owner can set its own dedicatedMsgSender");
        bytes32 slot = _DEDICATED_ADDR_SLOT;
        assembly {
            sstore(slot, dedicatedMsgSender)
        }
    }

    // make a payment (only dedicatedMsgSender)
    function sendToken(
        address token,
        uint256 amount,
        address payable to
    ) public onlyDedicatedMsgSender() {
        if (token == ETH) {
            to.transfer(amount);
        } else {
            IERC20(token).transfer(to, amount);
        }
    }
}
