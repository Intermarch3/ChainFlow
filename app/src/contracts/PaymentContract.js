export const PaymentAbi = [
    {
    "type": "function",
    "name": "sendERC20",
    "inputs": [
        {
        "name": "token",
        "type": "address",
        "internalType": "address"
        },
        {
        "name": "amount",
        "type": "uint256",
        "internalType": "uint256"
        },
        {
        "name": "to",
        "type": "address",
        "internalType": "address"
        }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
    },
    {
    "type": "function",
    "name": "sendETH",
    "inputs": [
        {
        "name": "amount",
        "type": "uint256",
        "internalType": "uint256"
        },
        {
        "name": "to",
        "type": "address",
        "internalType": "address payable"
        }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
    },
    {
    "type": "function",
    "name": "setDedicatedMsgSender",
    "inputs": [
        {
        "name": "dedicatedMsgSender",
        "type": "address",
        "internalType": "address"
        }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
    }
]

export const PaymentContractAddress = '0x8464135c8F25Da09e49BC8782676a84730C318bC'