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
import { http, createPublicClient, formatEther } from 'viem'
import { encodeFunctionData, parseEther, createWalletClient } from 'viem'
import { sepolia } from 'viem/chains'
import { privateKeyToAccount } from 'viem/accounts'
import { eip7702Actions } from 'viem/experimental'
import { PaymentAbi, PaymentContractAddress } from './contracts/PaymentContract'
import { CFAbi, CFContractAddress } from './contracts/ChainflowContract'
import { LinkTokenABI, LinkTokenAddress } from './contracts/LinkToken'

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
          chain: sepolia,
          transport: http(),
        }).extend(eip7702Actions())
        
        const publicClient = createPublicClient({
          chain: sepolia,
          transport: http(),
        })
        
        // Configuration des comptes
        const addr1 = "0x95464DF912299FCe8551B23199d3b30925e3D8FF"
        const acc2 = privateKeyToAccount('')
        
        this.addResult(`Compte 1: ${addr1}`)
        this.addResult(`Compte 2: ${acc2.address}`)
        
        // Signature de l'autorisation (! Attention nonce)
        const authorization = await walletClient.signAuthorization({
          account: acc2,
          contractAddress: PaymentContractAddress,
        })
        this.addResult(`Autorisation signée: ${this.safejsonStringify(authorization)}`)
        
        // // Première transaction
        const hash = await walletClient.sendTransaction({
          account: acc2,
          authorizationList: [authorization],
          data: encodeFunctionData({
            abi: PaymentAbi,
            functionName: 'setDedicatedMsgSender',
            args: [CFContractAddress]
          }),
          to: acc2.address,
        })
        this.addResult(`Hash de la première transaction: ${hash}`)
        
        // set link token allowance
        const hash2 = await walletClient.sendTransaction({
          account: acc2,
          data: encodeFunctionData({
            abi: LinkTokenABI,
            functionName: 'approve',
            args: [
              CFContractAddress,
              parseEther("5")
            ]
          }),
          to: LinkTokenAddress,
        })
        this.addResult(`Hash de la deuxieme transaction: ${hash2}`)

        // Deuxième transaction
        const hash3 = await walletClient.sendTransaction({
          account: acc2,
          data: encodeFunctionData({
            abi: CFAbi,
            functionName: 'newSubscription',
            args: [
            "0x0000000000000000000000000000000000000000",
            parseEther("0.05"),
            addr1,
            45,
            10,
            parseEther("5")
            ]
          }),
          to: CFContractAddress,
        })
        this.addResult(`Hash de la troisieme transaction: ${hash3}`)
        
        // Vérification des soldes
        const getETHBalance = async (publicClient, address) => {
          const balance = await publicClient.getBalance({ 
            address: address,
          })
          return formatEther(balance)
        }
        
        const balance1 = await getETHBalance(publicClient, addr1)
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
