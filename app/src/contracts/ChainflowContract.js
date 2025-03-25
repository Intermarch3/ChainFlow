export const CFAbi = [
    {
    "type": "constructor",
    "inputs": [
        {
        "name": "_paymentContract",
        "type": "address",
        "internalType": "address payable"
        },
        {
        "name": "_chainlinkRegistrar",
        "type": "address",
        "internalType": "address"
        },
        {
        "name": "_chainlinkRegistery",
        "type": "address",
        "internalType": "address"
        },
        {
        "name": "_linkToken",
        "type": "address",
        "internalType": "address"
        }
    ],
    "stateMutability": "nonpayable"
    },
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
    "name": "cancelSubscription",
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
        "type": "uint256",
        "internalType": "uint256"
        }
    ],
    "stateMutability": "nonpayable"
    },
    {
    "type": "function",
    "name": "chainlinkRegistery",
    "inputs": [],
    "outputs": [
        {
        "name": "",
        "type": "address",
        "internalType": "contract IAutomationRegistryConsumer"
        }
    ],
    "stateMutability": "view"
    },
    {
    "type": "function",
    "name": "chainlinkRegistrar",
    "inputs": [],
    "outputs": [
        {
        "name": "",
        "type": "address",
        "internalType": "contract AutomationRegistrarInterface"
        }
    ],
    "stateMutability": "view"
    },
    {
    "type": "function",
    "name": "checkUpkeep",
    "inputs": [
        {
        "name": "checkData",
        "type": "bytes",
        "internalType": "bytes"
        }
    ],
    "outputs": [
        {
        "name": "upkeepNeeded",
        "type": "bool",
        "internalType": "bool"
        },
        {
        "name": "performData",
        "type": "bytes",
        "internalType": "bytes"
        }
    ],
    "stateMutability": "view"
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
            "name": "interval",
            "type": "uint256",
            "internalType": "uint256"
            },
            {
            "name": "nextPayment",
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
            "type": "uint96",
            "internalType": "uint96"
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
            "name": "upKeepId",
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
    "name": "linkToken",
    "inputs": [],
    "outputs": [
        {
        "name": "",
        "type": "address",
        "internalType": "contract IERC20"
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
        "type": "uint96",
        "internalType": "uint96"
        },
        {
        "name": "to",
        "type": "address",
        "internalType": "address"
        },
        {
        "name": "interval",
        "type": "uint256",
        "internalType": "uint256"
        },
        {
        "name": "startInterval",
        "type": "uint256",
        "internalType": "uint256"
        },
        {
        "name": "linkAmount",
        "type": "uint96",
        "internalType": "uint96"
        }
    ],
    "outputs": [
        {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
        }
    ],
    "stateMutability": "payable"
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
    "name": "performUpkeep",
    "inputs": [
        {
        "name": "performData",
        "type": "bytes",
        "internalType": "bytes"
        }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
    },
    {
    "type": "function",
    "name": "setChainlinkRegistery",
    "inputs": [
        {
        "name": "_chainlinkRegistery",
        "type": "address",
        "internalType": "address"
        }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
    },
    {
    "type": "function",
    "name": "setChainlinkRegistrar",
    "inputs": [
        {
        "name": "_chainlinkRegistrar",
        "type": "address",
        "internalType": "address"
        }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
    },
    {
    "type": "function",
    "name": "setLinkToken",
    "inputs": [
        {
        "name": "_linkToken",
        "type": "address",
        "internalType": "address"
        }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
    },
    {
    "type": "function",
    "name": "setPaymentContract",
    "inputs": [
        {
        "name": "_paymentContract",
        "type": "address",
        "internalType": "address payable"
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
        "name": "interval",
        "type": "uint256",
        "internalType": "uint256"
        },
        {
        "name": "nextPayment",
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
        "type": "uint96",
        "internalType": "uint96"
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
        "name": "upKeepId",
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

export const CFContractAddress = '0xaD63C0c9cAFeC5c9b4b14171899cf945b4765a44'