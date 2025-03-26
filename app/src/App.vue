<template>
  <div>
    <div class="blockchain-section">
      <button @click="executeBlockchainScript" :disabled="isLoading">
        {{ isLoading ? 'Exécution en cours...' : 'Exécuter le script entier' }}
      </button>
      <button @click="executeWalletSetup" :disabled="isLoading">
        {{ isLoading ? 'Exécution en cours...' : 'Configurer le portefeuille' }}
      </button>
      <button @click="executeApprove" :disabled="isLoading">
        {{ isLoading ? 'Exécution en cours...' : 'Approuver le jeton LINK' }}
      </button>
      <button @click="executeNewSubscription" :disabled="isLoading">
        {{ isLoading ? 'Exécution en cours...' : 'Créer un nouvel abonnement' }}
      </button>
      <button @click="executeGetETHBalance" :disabled="isLoading">
        {{ isLoading ? 'Exécution en cours...' : 'Obtenir les solde ETH' }}
      </button>
      <div v-if="isLoading">Chargement...</div>
      <div v-if="results.length > 0" class="results">
        <h3>Résultats:</h3>
        <pre>{{ results.join('\n') }}</pre>
      </div>
    </div>
  </div>
</template>

<script>
import { http, createPublicClient, createWalletClient, zeroAddress } from 'viem'
import { sepolia } from 'viem/chains'
import { privateKeyToAccount } from 'viem/accounts'
import { eip7702Actions } from 'viem/experimental'
import { CFContractAddress } from './contracts/ChainflowContract'
import { approveLinkToken, newSubscription, setWalletToPaymentContract, getETHBalance } from './scripts'

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
const acc2 = privateKeyToAccount('0xce79c4c92de28296bcc6b3a0900079679c86144fddedf8414772562d1f29e9f9')

export default {
  name: 'App',
  data() {
    return {
      isLoading: false,
      results: [],
      wc: walletClient,
      pc: publicClient,
      addr1: addr1,
      acc2: acc2
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
        const acc2 = privateKeyToAccount('0xce79c4c92de28296bcc6b3a0900079679c86144fddedf8414772562d1f29e9f9')
        
        this.addResult(`Compte 1: ${addr1}`)
        this.addResult(`Compte 2: ${acc2.address}`)
        
        // setup wallet to payment contract
        const [auth, hash] = await setWalletToPaymentContract(walletClient, acc2)
        this;this.addResult(`Authorization: ${auth}`)
        this.addResult(`Hash de la première transaction: ${hash}`)
        
        // set link token allowance
        const hash2 = await approveLinkToken(walletClient, acc2, "5", CFContractAddress)
        this.addResult(`Hash de la deuxieme transaction: ${hash2}`)

        // create subscription
        const hash3 = await newSubscription(walletClient, acc2, "0.05", addr1, zeroAddress, "5", "30")
        this.addResult(`Hash de la troisieme transaction: ${hash3}`)
        
        // Vérification des soldes
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
    async executeApprove() {
      this.isLoading = true
      this.results = []
      try {
        // set link token allowance
        const hash2 = await approveLinkToken(walletClient, acc2, "5", CFContractAddress)
        this.addResult(`Hash de la deuxieme transaction: ${hash2}`)
      } catch (error) {
        this.addResult(`Erreur: ${error.message}\n${error.stack}`)
        console.error(error)
      } finally {
        this.isLoading = false
      }
    },
    async executeNewSubscription() {
      this.isLoading = true
      this.results = []
      try {
        // create subscription
        const hash3 = await newSubscription(walletClient, acc2, "0.05", addr1, zeroAddress, "5", "30")
        this.addResult(`Hash de la troisieme transaction: ${hash3}`)
      } catch (error) {
        this.addResult(`Erreur: ${error.message}\n${error.stack}`)
        console.error(error)
      } finally {
        this.isLoading = false
      }
    },
    async executeGetETHBalance() {
      this.isLoading = true
      this.results = []
      try {
        // Vérification des soldes
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
    async executeWalletSetup() {
      this.isLoading = true
      this.results = []
      try {
        // setup wallet to payment contract
        const [auth, hash] = await setWalletToPaymentContract(walletClient, acc2)
        this.addResult(`Authorization: ${auth}`)
        this.addResult(`Hash de la première transaction: ${hash}`)
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
  margin: 20px;
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
