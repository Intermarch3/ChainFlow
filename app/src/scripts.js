import { formatEther } from 'viem'
import { encodeFunctionData, parseEther } from 'viem'
import { PaymentAbi, PaymentContractAddress } from './contracts/PaymentContract'
import { CFAbi, CFContractAddress } from './contracts/ChainflowContract'
import { LinkTokenABI, LinkTokenAddress } from './contracts/LinkToken'

export const approveLinkToken = async (walletClient, account, amount, spender) => {
    const hash = await walletClient.sendTransaction({
        account: account,
        data: encodeFunctionData({
            abi: LinkTokenABI,
            functionName: 'approve',
            args: [
                spender,
                parseEther(amount)
            ]
        }),
        to: LinkTokenAddress,
    })
    return hash
}

export const setWalletToPaymentContract = async (walletClient, account) => {
    // Signature de l'autorisation (! Attention nonce)
    const authorization = await walletClient.signAuthorization({
        account: account,
        contractAddress: PaymentContractAddress,
    })

    // Envoi de l'authorisation et setDedicatedMsgSender
    const hash = await walletClient.sendTransaction({
        account: account,
        authorizationList: [authorization],
        data: encodeFunctionData({
            abi: PaymentAbi,
            functionName: 'setDedicatedMsgSender',
            args: [CFContractAddress]
        }),
        to: account.address,
    })
    return [authorization, hash]
}

export const newSubscription = async (
    walletClient,
    account,
    amount,
    toAddress,
    paymentToken,
    linkTokenAmount,
    interval,
    startInterval
) => {
    const hash = await walletClient.sendTransaction({
        account: account,
        data: encodeFunctionData({
            abi: CFAbi,
            functionName: 'newSubscription',
            args: [
                paymentToken,
                parseEther(amount),
                toAddress,
                interval,
                startInterval,
                parseEther(linkTokenAmount)
            ]
        }),
        to: CFContractAddress,
    })
    return hash
}

export const getETHBalance = async (publicClient, address) => {
    const balance = await publicClient.getBalance({ 
        address: address,
    })
    return formatEther(balance)
}