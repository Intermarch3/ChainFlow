<template>
  <div>
    <div class="blockchain-section">
      <button @click="executeBlockchainScript" :disabled="isLoading">
        {{ isLoading ? 'Exécution en cours...' : 'Exécuter le script blockchain' }}
      </button>
      
      <div v-if="results.length > 0" class="results">
        <h3>Résultats:</h3>
        <pre>{{ results.join('\n') }}</pre>
      </div>
    </div>
  </div>
</template>

<script>
import { createWalletClient, http, encodeFunctionData, createPublicClient, formatEther, parseEther, zeroAddress } from 'viem'
import { anvil } from 'viem/chains'
import { privateKeyToAccount } from 'viem/accounts'
import { eip7702Actions } from 'viem/experimental'
import { PaymentAbi, PaymentContractAddress } from './contracts/PaymentContract'
import { CFAbi, CFContractAddress } from './contracts/ChainflowContract'

export default {
  name: 'App',
  data() {
    return {
      isLoading: false,
      results: []
    }
  },
  methods: {
    // Helper function to stringify objects with BigInt values
    safejsonStringify(obj) {
      return JSON.stringify(obj, (key, value) => 
        typeof value === 'bigint' ? value.toString() : value
      );
    },
    async executeBlockchainScript() {
      this.isLoading = true
      this.results = []
      
      try {
        // Création des clients
        const walletClient = createWalletClient({
          chain: anvil,
          transport: http(),
        }).extend(eip7702Actions())
        
        const publicClient = createPublicClient({
          chain: anvil,
          transport: http(),
        })
        
        // Configuration des comptes
        const acc1 = privateKeyToAccount('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80')
        const acc2 = privateKeyToAccount('0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d')
        
        this.addResult(`Compte 1: ${acc1.address}`)
        this.addResult(`Compte 2: ${acc2.address}`)
        
        // Signature de l'autorisation (! Attention nonce)
        const authorization = await walletClient.signAuthorization({
          account: acc1,
          contractAddress: PaymentContractAddress,
        })
        this.addResult(`Autorisation signée: ${this.safejsonStringify(authorization)}`)
        
        // Première transaction
        const hash = await walletClient.sendTransaction({
          account: acc1,
          authorizationList: [authorization],
          data: encodeFunctionData({
            abi: PaymentAbi,
            functionName: 'setDedicatedMsgSender',
            args: [CFContractAddress]
          }),
          to: acc1.address,
        })
        this.addResult(`Hash de la première transaction: ${hash}`)
        
        // Deuxième transaction
        const hash2 = await walletClient.sendTransaction({
          account: acc1,
          data: encodeFunctionData({
            abi: CFAbi,
            functionName: 'newSubscription',
            args: [
              zeroAddress,
              parseEther("10"),
              acc2.address,
              60
            ]
          }),
          to: CFContractAddress,
        })
        this.addResult(`Hash de la deuxième transaction: ${hash2}`)
        
        // Vérification des soldes
        const getETHBalance = async (publicClient, address) => {
          const balance = await publicClient.getBalance({ 
            address: address,
          })
          return formatEther(balance)
        }
        
        const balance1 = await getETHBalance(publicClient, acc1.address)
        const balance2 = await getETHBalance(publicClient, acc2.address)
        
        this.addResult(`Solde du compte 1: ${balance1} ETH`)
        this.addResult(`Solde du compte 2: ${balance2} ETH`)
        
      } catch (error) {
        this.addResult(`Erreur: ${error.message}\n${error.stack}`)
        console.error(error)
      } finally {
        this.isLoading = false
      }
    },
    
    addResult(message) {
      this.results.push(message)
      console.log(message)
    }
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

.blockchain-section {
  padding: 20px;
}

button {
  background-color: #42b983;
  color: white;
  padding: 10px 20px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
  transition: background-color 0.3s;
}

button:hover {
  background-color: #3aa876;
}

button:disabled {
  background-color: #a0cfbb;
  cursor: not-allowed;
}

.results {
  margin-top: 20px;
  text-align: left;
  background-color: #f8f8f8;
  padding: 15px;
  border-radius: 4px;
  border: 1px solid #ddd;
  max-height: 400px;
  overflow-y: auto;
}

pre {
  white-space: pre-wrap;
  word-break: break-word;
}
</style>
