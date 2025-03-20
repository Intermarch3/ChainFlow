export const CFAbi = [
    {
    "type": "constructor",
    "inputs": [
        {
        "name": "_paymentContract",
        "type": "address",
        "internalType": "address"
        }
    ],
    "stateMutability": "nonpayable"
    },
    {
    "type": "function",
    "name": "getMySubscriptions",
    "inputs": [],
    "outputs": [
        {
        "name": "",
        "type": "uint256[]",
        "internalType": "uint256[]"
        }
    ],
    "stateMutability": "view"
    },
    {
    "type": "function",
    "name": "getPaymentContract",
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
    "name": "getSubscription",
    "inputs": [
        {
        "name": "index",
        "type": "uint256",
        "internalType": "uint256"
        }
    ],
    "outputs": [
        {
        "name": "",
        "type": "tuple",
        "internalType": "struct ChainflowContract.Subscription",
        "components": [
            {
            "name": "active",
            "type": "bool",
            "internalType": "bool"
            },
            {
            "name": "timePadding",
            "type": "uint256",
            "internalType": "uint256"
            },
            {
            "name": "lastPayment",
            "type": "uint256",
            "internalType": "uint256"
            },
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
            },
            {
            "name": "from",
            "type": "address",
            "internalType": "address"
            },
            {
            "name": "taskId",
            "type": "uint256",
            "internalType": "uint256"
            }
        ]
        }
    ],
    "stateMutability": "view"
    },
    {
    "type": "function",
    "name": "newSubscription",
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
        },
        {
        "name": "timePadding",
        "type": "uint256",
        "internalType": "uint256"
        }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
    },
    {
    "type": "function",
    "name": "owner",
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
    "name": "paymentContract",
    "inputs": [],
    "outputs": [
        {
        "name": "",
        "type": "address",
        "internalType": "contract ChainflowPayment"
        }
    ],
    "stateMutability": "view"
    },
    {
    "type": "function",
    "name": "setPaymentContract",
    "inputs": [
        {
        "name": "_paymentContract",
        "type": "address",
        "internalType": "address"
        }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
    },
    {
    "type": "function",
    "name": "subscriptions",
    "inputs": [
        {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
        }
    ],
    "outputs": [
        {
        "name": "active",
        "type": "bool",
        "internalType": "bool"
        },
        {
        "name": "timePadding",
        "type": "uint256",
        "internalType": "uint256"
        },
        {
        "name": "lastPayment",
        "type": "uint256",
        "internalType": "uint256"
        },
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
        },
        {
        "name": "from",
        "type": "address",
        "internalType": "address"
        },
        {
        "name": "taskId",
        "type": "uint256",
        "internalType": "uint256"
        }
    ],
    "stateMutability": "view"
    },
    {
    "type": "function",
    "name": "userNbSubs",
    "inputs": [
        {
        "name": "",
        "type": "address",
        "internalType": "address"
        }
    ],
    "outputs": [
        {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
        }
    ],
    "stateMutability": "view"
    }
]

export const CFContractAddress = '0x71C95911E9a5D330f4D621842EC243EE1343292e'