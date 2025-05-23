export const PaymentAbi = [
    {
    "type": "fallback",
    "stateMutability": "payable"
    },
    {
    "type": "receive",
    "stateMutability": "payable"
    },
    {
    "type": "function",
    "name": "chainflowPaymentVersion",
    "inputs": [],
    "outputs": [
        {
        "name": "",
        "type": "string",
        "internalType": "string"
        }
    ],
    "stateMutability": "view"
    },
    {
    "type": "function",
    "name": "getDedicatedMsgSender",
    "inputs": [],
    "outputs": [
        {
        "name": "",
        "type": "address",
        "internalType": "address"
        }
    ],
    "stateMutability": "view"
    },
    {
    "type": "function",
    "name": "sendToken",
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
    },
    {
    "type": "event",
    "name": "ChainflowPaymentDedicatedMsgSenderSet",
    "inputs": [
        {
        "name": "wallet",
        "type": "address",
        "indexed": false,
        "internalType": "address"
        },
        {
        "name": "dedicatedMsgSender",
        "type": "address",
        "indexed": false,
        "internalType": "address"
        }
    ],
    "anonymous": false
    },
    {
    "type": "event",
    "name": "ChainflowPaymentSent",
    "inputs": [
        {
        "name": "token",
        "type": "address",
        "indexed": false,
        "internalType": "address"
        },
        {
        "name": "amount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
        },
        {
        "name": "from",
        "type": "address",
        "indexed": false,
        "internalType": "address"
        },
        {
        "name": "to",
        "type": "address",
        "indexed": false,
        "internalType": "address"
        },
        {
        "name": "timestamp",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
        }
    ],
    "anonymous": false
    }
]

export const PaymentContractAddress = '0x973c5F90d1Fdd41c7befD3b2dcA48f73609A3b46'