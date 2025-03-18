export const abi = [
    {
        "type": "function",
        "name": "count",
        "inputs": [],
        "outputs": [
        {
            "name": "",
            "type": "uint256",
            "internalType": "uint256"
        }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "init",
        "inputs": [],
        "outputs": [
        {
            "name": "",
            "type": "uint256",
            "internalType": "uint256"
        }
        ],
        "stateMutability": "pure"
    },
    {
        "type": "function",
        "name": "init2",
        "inputs": [],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "sendMoney",
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
    }
]

export const contractAddress = '0x8464135c8F25Da09e49BC8782676a84730C318bC'