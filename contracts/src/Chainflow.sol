// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { AutomationCompatibleInterface } from '../node_modules/@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol';
import { IAutomationRegistryConsumer } from '../node_modules/@chainlink/contracts/src/v0.8/automation/interfaces/IAutomationRegistryConsumer.sol';

// struct for automation registration params
struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    uint8 triggerType;
    bytes checkData;
    bytes triggerConfig;
    bytes offchainConfig;
    uint96 amount;
}

interface AutomationRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);
}


contract ChainflowContract is AutomationCompatibleInterface {
    struct Subscription {
        bool active;
        uint256 interval;
        uint256 nextPayment;
        address token;
        uint96 amount;
        address to;
        address from;
        uint256 upKeepId;
    }

    address public immutable owner;
    IERC20 public linkToken;
    IAutomationRegistryConsumer public chainlinkRegistery;
    AutomationRegistrarInterface public chainlinkRegistrar;
    ChainflowPayment public paymentContract;
    Subscription[] public subscriptions;
    mapping(address => uint256) public userNbSubs;

    constructor(address payable _paymentContract, address _chainlinkRegistrar, address _chainlinkRegistery, address _linkToken) {
        owner = msg.sender;
        chainlinkRegistrar = AutomationRegistrarInterface(_chainlinkRegistrar);
        chainlinkRegistery = IAutomationRegistryConsumer(_chainlinkRegistery);
        paymentContract = ChainflowPayment(_paymentContract);
        linkToken = IERC20(_linkToken);
    }


    //////////////////////////////////////////////////////////
    //                                                      //
    //                  Setters functions                   //
    //                                                      //
    //////////: AutomationCompatibleInterface :///////////////

    // change paymentContract implementation address
    function setPaymentContract(address payable _paymentContract) public {
        require(msg.sender == owner, "Only owner can set payment contract");
        paymentContract = ChainflowPayment(_paymentContract);
    }

    function setChainlinkRegistrar(address _chainlinkRegistrar) public {
        require(msg.sender == owner, "Only owner can set chainlink registrar");
        chainlinkRegistrar = AutomationRegistrarInterface(_chainlinkRegistrar);
    }

    function setChainlinkRegistery(address _chainlinkRegistery) public {
        require(msg.sender == owner, "Only owner can set chainlink registery");
        chainlinkRegistery = IAutomationRegistryConsumer(_chainlinkRegistery);
    }

    function setLinkToken(address _linkToken) public {
        require(msg.sender == owner, "Only owner can set link token");
        linkToken = IERC20(_linkToken);
    }


    //////////////////////////////////////////////////////////
    //                                                      //
    //                Subscriptions functions               //
    //                                                      //
    //////////////////////////////////////////////////////////

    // create a subscription, register upkeep and add funds to upkeep
    function newSubscription(
        address token,
        uint96 amount,
        address to,
        uint256 interval,
        uint256 startInterval,
        uint96 linkAmount
    ) payable external returns(uint256) {
        require(amount > 0, "Amount must be greater than 0");
        require(interval > 0, "Interval must be greater than 0");
        require(linkAmount <= linkToken.allowance(msg.sender, address(this)),
            "Not enough allowance for link token");
        linkToken.transferFrom(msg.sender, address(this), linkAmount);
        linkToken.approve(address(chainlinkRegistrar), linkAmount);
        Subscription memory sub;
        sub.active = true;
        sub.interval = interval;
        sub.nextPayment = block.timestamp + startInterval;
        sub.token = token;
        sub.amount = amount;
        sub.to = to;
        sub.from = msg.sender;
        sub.upKeepId = _registerUpKeep(sub, linkAmount);
        subscriptions.push(sub);
        userNbSubs[msg.sender]++;
        return sub.upKeepId;
    }

    // register upkeep for a subscription with msg.sender as upKeep owner
    function _registerUpKeep(Subscription memory sub, uint96 linkAmount) internal returns(uint256){
        RegistrationParams memory regParams;
        uint256 upKeepId;

        regParams.upkeepContract = address(this);
        regParams.amount = linkAmount;
        regParams.adminAddress = address(sub.from);
        regParams.gasLimit = 800000;
        regParams.triggerType = 0;
        regParams.name = "ChainFlow Subscription";
        regParams.encryptedEmail = "";
        regParams.checkData = abi.encode(subscriptions.length);
        regParams.triggerConfig = "";
        regParams.offchainConfig = "";

        upKeepId = chainlinkRegistrar.registerUpkeep(regParams);
        if (upKeepId == 0) revert("Upkeep registration failed");
        return upKeepId;
    }

    // cancel a subscription (upKeep need to be canceled by owner)
    function cancelSubscription(uint256 index) external returns(uint256) {
        require(subscriptions.length >index, "Index out of bounds");
        require(subscriptions[index].from == msg.sender,
            "You are not the owner of this subscription");
        subscriptions[index].active = false;
        userNbSubs[msg.sender]--;
        return subscriptions[index].upKeepId;
    }

    // function called by chainlink automations to pay a subscription
    function performUpkeep(bytes calldata performData) external {
        uint256 index = abi.decode(performData, (uint256));
        Subscription memory sub = subscriptions[index];
        require(subscriptions.length > index, "Index out of bounds");
        require(sub.active, "Subscription is not active");
        require(block.timestamp >= sub.nextPayment, "Not time to pay yet");

        ChainflowPayment(payable(sub.from)).sendToken(
            subscriptions[index].token,
            subscriptions[index].amount,
            payable(subscriptions[index].to)
        );
        subscriptions[index].nextPayment += sub.interval;
    }

    // function called by chainlink automations to check if a subscription need to be paid
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
        uint256 index = abi.decode(checkData, (uint256));
        if (subscriptions.length <= index ||
            !subscriptions[index].active ||
            block.timestamp < subscriptions[index].nextPayment) {
            return (false, "");
        }
        return (true, checkData);
    }


    //////////////////////////////////////////////////////////
    //                                                      //
    //                  Getters functions                   //
    //                                                      //
    //////////////////////////////////////////////////////////

    // get implementation address
    function getPaymentContract() external view returns (address) {
        return address(paymentContract);
    }

    // get list of index for each subscriptions msg.sender have
    function getMySubscriptions() external view returns (uint256[] memory) {
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
    function getSubscription(uint256 index) external view returns (Subscription memory) {
        require(subscriptions.length > index, "Index out of bounds");
        require(subscriptions[index].from == msg.sender,
            "You are not the owner of this subscription");
        return subscriptions[index];
    }

    receive() external payable {}

    fallback() external payable {}
}



contract ChainflowPayment {
    bytes32 private constant _DEDICATED_ADDR_SLOT = 
        bytes32(uint256(keccak256("chainflow.dedicatedMsgSender")) - 1);

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
        if (token == address(0)) {
            to.transfer(amount);
        } else {
            IERC20(token).transfer(to, amount);
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
