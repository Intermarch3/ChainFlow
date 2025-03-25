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
    }
]

export const PaymentContractAddress = '0xEC4a3DBCef2d57B0eB861092d584AFCAa832c0FD'