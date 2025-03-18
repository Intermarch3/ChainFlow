import { createApp } from 'vue'
import App from './App.vue'
import { createWalletClient, http, encodeFunctionData, createPublicClient, formatEther } from 'viem'
import { parseEther } from 'viem'
import { anvil } from 'viem/chains'
import { privateKeyToAccount } from 'viem/accounts'
import { eip7702Actions } from 'viem/experimental'

import { abi, contractAddress } from './contracts/TestContract'

const walletClient = createWalletClient({
  chain: anvil,
  transport: http(),
}).extend(eip7702Actions())

const publicClient = createPublicClient({
  chain: anvil,
  transport: http(),
})

const acc1 = privateKeyToAccount('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80')
const acc2 = privateKeyToAccount('0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d')
console.log(walletClient, acc1)

const authorization = await walletClient.signAuthorization({
    account: acc1,
    contractAddress: contractAddress,
}) 

console.log(authorization)

const hash = await walletClient.sendTransaction({
    account: acc1,
    authorizationList: [authorization],
    data: encodeFunctionData({
      abi,
      functionName: 'init2',
      args: []
    }),
    to: contractAddress,
})

console.log(hash)

const hash2 = await walletClient.sendTransaction({
    account: acc2,
    data: encodeFunctionData({
      abi,
      functionName: 'sendMoney',
      args: [parseEther("10"), acc2.address]
    }),
    to: acc1.address,
})

console.log(hash2)

const getETHBalance = async (publicClient, address) => {
    const balance = await publicClient.getBalance({ 
        address: address,
    })
    return formatEther(balance)
}

console.log("acc1 balance: ", await getETHBalance(publicClient, acc1.address))
console.log("acc2 balance: ", await getETHBalance(publicClient, acc2.address))

createApp(App).mount('#app')
