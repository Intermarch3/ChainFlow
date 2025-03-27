<template>
  <div id="app">
    <header class="app-header">
      <div class="logo">
        <h1>ChainFlow</h1>
      </div>
      <div class="wallet-connect">
        <button v-if="!isConnected" @click="connectWallet" class="connect-btn">
          Connect Wallet
        </button>
        <div v-else class="wallet-info">
          <span class="address">{{ truncatedAddress }}</span>
          <button @click="disconnectWallet" class="disconnect-btn">Disconnect</button>
        </div>
      </div>
    </header>

    <main class="main-content">
      <div v-if="isConnected">
        <section class="subscriptions-list">
          <h2>Mes Abonnements</h2>
          <div v-if="loading" class="loading-spinner">
            <div class="spinner"></div>
            <p>Chargement des abonnements...</p>
          </div>
          
          <div v-else-if="subscriptions.length === 0" class="no-subscriptions">
            <p>Vous n'avez pas encore d'abonnements actifs.</p>
          </div>
          
          <div v-else class="subscriptions-grid">
            <div 
              v-for="(subscription, index) in subscriptions" 
              :key="index"
              class="subscription-card"
              @click="showSubscriptionDetails(subscription)"
            >
              <div class="subscription-status" :class="{ 'active': subscription.active }">
                {{ subscription.active ? 'Actif' : 'Inactif' }}
              </div>
              <div class="subscription-amount">
                <strong>{{ formatAmount(subscription.amount) }}</strong>
                <span>{{ isNativeToken(subscription.token) ? 'ETH' : 'ERC-20' }}</span>
              </div>
              <div class="subscription-interval">
                Tous les {{ formatInterval(subscription.interval) }}
              </div>
              <div class="subscription-next">
                Prochain paiement: {{ formatDate(subscription.nextPayment) }}
              </div>
            </div>
          </div>
        </section>

        <div class="create-subscription">
          <button @click="openCreateSubscriptionModal" class="create-btn">
            Créer une subscription
          </button>
        </div>
      </div>
      
      <div v-else class="not-connected">
        <p>Connectez votre portefeuille pour accéder à vos abonnements.</p>
      </div>
    </main>

    <!-- Modal de création de subscription -->
    <SubscriptionModal 
      v-if="showCreateModal" 
      @close="closeCreateSubscriptionModal"
      @confirm="confirmSubscription"
    />

    <!-- Modal de détails de subscription -->
    <SubscriptionDetailsModal 
      v-if="selectedSubscription !== null" 
      :subscription="selectedSubscription"
      @close="closeSubscriptionDetails"
      @delete="deleteSubscription"
    />

    <!-- Modal des transactions -->
    <TransactionsModal
      v-if="showTransactionsModal"
      :transactions="pendingTransactions"
      @close="closeTransactionsModal"
      @sign="signTransaction"
      @finish="finishTransactions"
    />
  </div>
</template>

<script>
import { createPublicClient, createWalletClient, http, formatEther, parseEther, encodeFunctionData, zeroAddress } from 'viem'
import { sepolia } from 'viem/chains'
import { CFAbi, CFContractAddress } from './contracts/ChainflowContract'
import { LinkTokenABI, LinkTokenAddress } from './contracts/LinkToken'
import { PaymentAbi, PaymentContractAddress } from './contracts/PaymentContract'
import { eip7702Actions } from 'viem/experimental'
import { privateKeyToAccount } from 'viem/accounts'

// Import des composants
import SubscriptionModal from './components/SubscriptionModal.vue'
import SubscriptionDetailsModal from './components/SubscriptionDetailsModal.vue'
import TransactionsModal from './components/TransactionsModal.vue'

export default {
  name: 'App',
  components: {
    SubscriptionModal,
    SubscriptionDetailsModal,
    TransactionsModal
  },
  data() {
    return {
      // État de connexion
      isConnected: false,
      walletAddress: null,
      walletIsChainflowPayment: false,
      isDevMode: false,
      privateKeyAccount: null,
      
      // Clients blockchain
      publicClient: null,
      walletClient: null,
      
      // État de l'UI
      loading: false,
      error: null,
      
      // Données des subscriptions
      subscriptions: [],
      selectedSubscription: null,
      
      // État des modales
      showCreateModal: false,
      showTransactionsModal: false,
      
      // Données de transactions
      pendingTransactions: [],
      currentTransactionIndex: 0,
      
      // Données temporaires pour la nouvelle subscription
      newSubscriptionData: null
    }
  },
  computed: {
    truncatedAddress() {
      if (!this.walletAddress) return ''
      return `${this.walletAddress.slice(0, 6)}...${this.walletAddress.slice(-4)}`
    }
  },
  methods: {
    // Connexion wallet
    async connectWallet() {
      try {
        // Vérifier si nous sommes en mode développement
        this.checkDevMode();
        
        // Initialiser les clients
        this.publicClient = createPublicClient({
          chain: sepolia,
          transport: http()
        });
        
        // Si en mode dev et que la clé privée est disponible, utiliser cette clé
        if (this.isDevMode && process.env.WALLET_PRIVATE_KEY) {
          try {
            // Créer un compte à partir de la clé privée
            this.privateKeyAccount = privateKeyToAccount(`0x${process.env.WALLET_PRIVATE_KEY}`);
            
            // Créer un client wallet en utilisant la clé privée
            this.walletClient = createWalletClient({
              chain: sepolia,
              transport: http(),
              account: this.privateKeyAccount
            }).extend(eip7702Actions());
            
            // Définir l'adresse du wallet
            this.walletAddress = this.privateKeyAccount.address;
            this.isConnected = true;
            console.log("Connecté avec la clé privée:", this.truncatedAddress);
            
            // Vérifier si le wallet utilise déjà l'implémentation ChainflowPayment
            await this.checkWalletImplementation();
            
            // Charger les abonnements
            this.loadSubscriptions();
            
            return; // Sortir de la méthode car on est déjà connecté
          } catch (error) {
            console.error("Erreur lors de l'utilisation de la clé privée:", error);
            console.warn("Retour au mode de connexion standard avec MetaMask");
            // Continuer avec la méthode standard si la clé privée échoue
          }
        }
        
        // Mode de connexion standard avec MetaMask
        this.walletClient = createWalletClient({
          chain: sepolia,
          transport: http(process.env.VUE_APP_RPC_URL || 'https://sepolia.drpc.org')
        }).extend(eip7702Actions());
        
        // Demander la connexion via metamask
        if (window.ethereum) {
          const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
          if (accounts.length > 0) {
            this.walletAddress = accounts[0];
            this.isConnected = true;
            
            // Vérifier si le wallet utilise déjà l'implémentation ChainflowPayment
            await this.checkWalletImplementation();
            
            // Charger les abonnements
            this.loadSubscriptions();
            
            // Écouter les changements de compte
            window.ethereum.on('accountsChanged', this.handleAccountsChanged);
          }
        } else {
          alert('Veuillez installer MetaMask pour utiliser cette application');
        }
      } catch (error) {
        console.error('Erreur lors de la connexion:', error);
        this.error = 'Impossible de se connecter au portefeuille';
      }
    },
    
    // Vérifier si le mode développement est activé
    checkDevMode() {
      // Récupérer la variable d'environnement DEVMODE
      const devMode = process.env.DEVMODE;
      this.isDevMode = devMode === 'true' || devMode === true;
      console.log("Mode développement:", this.isDevMode);
      
      if (this.isDevMode) {
        if (process.env.WALLET_PRIVATE_KEY) {
          console.log("Clé privée disponible pour le mode développement");
        } else {
          console.warn("Mode développement activé mais aucune clé privée trouvée");
        }
      }
    },

    // Déconnexion wallet
    disconnectWallet() {
      this.isConnected = false
      this.walletAddress = null
      this.subscriptions = []
      this.selectedSubscription = null
      
      // Retirer les listeners
      if (window.ethereum) {
        window.ethereum.removeListener('accountsChanged', this.handleAccountsChanged)
      }
    },
    
    // Gestion des changements de compte
    handleAccountsChanged(accounts) {
      if (accounts.length === 0) {
        this.disconnectWallet()
      } else if (this.walletAddress !== accounts[0]) {
        this.walletAddress = accounts[0]
        this.loadSubscriptions()
      }
    },
    
    // Chargement des abonnements
    async loadSubscriptions() {
      if (!this.isConnected || !this.publicClient) return
      
      this.loading = true
      this.subscriptions = []
      
      try {
        // Récupérer les IDs des abonnements de l'utilisateur
        const subscriptionIds = await this.publicClient.readContract({
          address: CFContractAddress,
          abi: CFAbi,
          functionName: 'getMySubscriptions',
          args: [
            this.walletAddress
          ],
          account: this.walletAddress
        })
        
        // Récupérer les détails de chaque abonnement
        for (const id of subscriptionIds) {
          const subscription = await this.publicClient.readContract({
            address: CFContractAddress,
            abi: CFAbi,
            functionName: 'getSubscription',
            args: [id],
            account: this.walletAddress
          })
          
          // Ajouter l'ID à l'objet
          subscription.id = id
          this.subscriptions.push(subscription)

          // Vérifier si le wallet est un contrat de paiement Chainflow
          this.walletIsChainflowPayment = await this.checkWalletImplementation()
          console.log("walletIsChainflowPayment", this.walletIsChainflowPayment)
        }
      } catch (error) {
        console.error('Erreur lors du chargement des abonnements:', error)
        this.error = 'Impossible de charger les abonnements'
      } finally {
        this.loading = false
      }
    },
    
    // Formater les montants
    formatAmount(amount) {
      return formatEther(amount)
    },
    
    // Vérifier si c'est un token natif (ETH)
    isNativeToken(tokenAddress) {
      return tokenAddress.toLowerCase() === zeroAddress.toLowerCase()
    },
    
    // Formater les intervalles en texte humain
    formatInterval(intervalInSeconds) {
      if (intervalInSeconds < 60) {
        return `${intervalInSeconds} secondes`
      } else if (intervalInSeconds < 3600) {
        const minutes = Math.floor(intervalInSeconds / 60)
        return `${minutes} minute${minutes > 1 ? 's' : ''}`
      } else if (intervalInSeconds < 86400) {
        const hours = Math.floor(intervalInSeconds / 3600)
        return `${hours} heure${hours > 1 ? 's' : ''}`
      } else {
        const days = Math.floor(intervalInSeconds / 86400)
        return `${days} jour${days > 1 ? 's' : ''}`
      }
    },
    
    // Formater les timestamps en dates lisibles
    formatDate(timestamp) {
      const date = new Date(Number(timestamp) * 1000)
      return date.toLocaleString()
    },
    
    // Afficher les détails d'un abonnement
    showSubscriptionDetails(subscription) {
      this.selectedSubscription = subscription
    },
    
    // Fermer les détails d'un abonnement
    closeSubscriptionDetails() {
      this.selectedSubscription = null
    },
    
    // Ouvrir le modal de création d'abonnement
    openCreateSubscriptionModal() {
      this.showCreateModal = true
    },
    
    // Fermer le modal de création d'abonnement
    closeCreateSubscriptionModal() {
      this.showCreateModal = false
      this.newSubscriptionData = null
    },
    
    // Confirmer la création d'un abonnement
    confirmSubscription(subscriptionData) {
      // Fermer le modal de création
      this.closeCreateSubscriptionModal()
      
      // Stocker les données pour le processus de création
      this.newSubscriptionData = subscriptionData
      
      // Préparer les transactions nécessaires
      this.preparePendingTransactions(subscriptionData)
      
      // Ouvrir le modal des transactions
      this.showTransactionsModal = true
    },

    // check if the wallet is using ChainflowPayment contract implem
    async checkWalletImplementation() {
      try {
        console.log("checkWalletImplementation")
        const str = await this.publicClient.readContract({
          address: this.walletAddress,
          abi: PaymentAbi,
          functionName: 'chainflowPaymentVersion',
        })
        // check if str start with "Chainflow payment"
        console.log("checkWalletImplementation", str)
        if (str.startsWith('Chainflow payment'))
          return true
        return false
      } catch (error) {
        return false
      }
    },

    async getTokenBalance(tokenAddress) {
      try {
        const balance = await this.publicClient.readContract({
          address: tokenAddress,
          abi: LinkTokenABI,
          functionName: 'balanceOf',
          args: [this.walletAddress]
        })
        return balance
      } catch (error) {
        console.error('Erreur lors de la récupération du solde du token:', error)
        return 0
      }
    },

    async getTokenAllowance(tokenAddress, allowedAddress) {
      try {
        const allowance = await this.publicClient.readContract({
          address: tokenAddress,
          abi: LinkTokenABI,
          functionName: 'allowance',
          args: [this.walletAddress, allowedAddress]
        })
        return allowance
      } catch (error) {
        console.error('Erreur lors de la récupération de l\'approbation du token:', error)
        return 0
      }
    },

    // check if the wallet dedicatedMsgSender is the Chainflow contract
    async checkWalletDedicatedMsgSender() {
      try {
        console.log("checkWalletImplementation")
        const addr = await this.publicClient.readContract({
          address: this.walletAddress,
          abi: PaymentAbi,
          functionName: 'getDedicatedMsgSender',
          args: []
        })
        if (addr === CFContractAddress)
          return true
        return false
      } catch (error) {
        console.error('Erreur lors de la vérification de l\'address du dedicatedMsgSender:', error)
        return false
      }
    },
    
    // Préparer les transactions nécessaires pour créer un abonnement
    preparePendingTransactions(data) {
      this.pendingTransactions = []
      this.pendingTransactions.push(
        {
          txType: 1,
          id: this.pendingTransactions.length + 1,
          name: 'Transformation du wallet en contrat de paiement',
          description: 'Autoriser le contrat ChainFlow à effectuer des paiements',
          status: this.walletIsChainflowPayment ? 'success' : 'pending',
          hash: null
        }
      )
      
      // Si c'est un token ERC-20, on ajoute l'approbation
      if (!this.isNativeToken(data.tokenAddress)) {
        this.pendingTransactions.push({
          type: 2,
          id: this.pendingTransactions.length + 1,
          name: 'Approbation du token ERC-20',
          description: `Autoriser le contrat ChainFlow à utiliser vos tokens ${data.tokenSymbol || 'ERC-20'}`,
          status: 'pending',
          hash: null
        })
      }
      
      // Ajouter les transactions pour LINK et création de l'abonnement
      this.pendingTransactions.push(
        {
          type: 2,
          id: this.pendingTransactions.length + 1,
          name: 'Approbation des tokens LINK',
          description: 'Autoriser le contrat ChainFlow à utiliser vos tokens LINK pour Chainlink Automation',
          status: 'pending',
          hash: null
        },
        {
          type: 3,
          id: this.pendingTransactions.length + 2,
          name: 'Création de l\'abonnement',
          description: 'Finaliser la création de l\'abonnement récurrent',
          status: 'pending',
          hash: null
        }
      )
      
      // Réinitialiser l'index de transaction courante
      this.currentTransactionIndex = this.walletIsChainflowPayment ? 1 : 0
    },
    
    // Fermer le modal des transactions
    closeTransactionsModal() {
      this.showTransactionsModal = false
      this.pendingTransactions = []
      this.currentTransactionIndex = 0
      this.newSubscriptionData = null
    },
    
    // Signer la transaction courante
    async signTransaction() {
      if (!this.newSubscriptionData || this.currentTransactionIndex >= this.pendingTransactions.length) {
        return;
      }
      
      const currentTx = this.pendingTransactions[this.currentTransactionIndex];
      currentTx.status = 'processing';
      
      try {
        let hash;
        let authorization;
        let interval;
        
        // Calculer l'ID de la transaction en fonction de l'implémentation
        const txId = this.isChainflowPaymentImplemented ? 
          currentTx.id : // Si l'implémentation est déjà présente, utiliser l'ID tel quel
          currentTx.id + 1; // Sinon, ajuster l'ID (car la première transaction est absente)
        
        // Exécuter la transaction en fonction de son ID de type
        switch (txId) {
          case 1:
            // Déploiement du contrat de paiement / Autorisation
            const accountParam = this.isDevMode && this.privateKeyAccount ? 
              this.privateKeyAccount.address : 
              this.walletAddress;
              
            authorization = await this.walletClient.signAuthorization({
              account: accountParam,
              contractAddress: PaymentContractAddress,
            });
            
            hash = await this.walletClient.sendTransaction({
              account: accountParam,
              authorizationList: [authorization],
              data: encodeFunctionData({
                abi: PaymentAbi,
                functionName: 'setDedicatedMsgSender',
                args: [CFContractAddress]
              }),
              to: this.walletAddress,
            });
            break;
            
          case 2:
            // Approbation du token ERC-20
            hash = await this.walletClient.sendTransaction({
              account: this.isDevMode && this.privateKeyAccount ? 
                this.privateKeyAccount.address : 
                this.walletAddress,
              data: encodeFunctionData({
                abi: LinkTokenABI, 
                functionName: 'approve',
                args: [
                  CFContractAddress,
                  parseEther(this.newSubscriptionData.amount.toString())
                ]
              }),
              to: this.newSubscriptionData.tokenAddress,
            });
            break;
            
          case 3:
            // Approbation des tokens LINK
            hash = await this.walletClient.sendTransaction({
              account: this.isDevMode && this.privateKeyAccount ? 
                this.privateKeyAccount.address : 
                this.walletAddress,
              data: encodeFunctionData({
                abi: LinkTokenABI,
                functionName: 'approve',
                args: [
                  CFContractAddress,
                  parseEther(this.newSubscriptionData.linkAmount.toString())
                ]
              }),
              to: LinkTokenAddress,
            });
            break;
            
          case 4:
            // Création de l'abonnement
            interval = this.calculateIntervalInSeconds(
              this.newSubscriptionData.intervalValue,
              this.newSubscriptionData.intervalUnit
            );
            
            hash = await this.walletClient.sendTransaction({
              account: this.isDevMode && this.privateKeyAccount ? 
                this.privateKeyAccount.address : 
                this.walletAddress,
              data: encodeFunctionData({
                abi: CFAbi,
                functionName: 'newSubscription',
                args: [
                  this.newSubscriptionData.tokenAddress,
                  parseEther(this.newSubscriptionData.amount.toString()),
                  this.newSubscriptionData.recipientAddress,
                  interval,
                  this.newSubscriptionData.startDelay,
                  parseEther(this.newSubscriptionData.linkAmount.toString()),
                  this.newSubscriptionData.paymentsCount
                ]
              }),
              to: CFContractAddress,
              value: this.isNativeToken(this.newSubscriptionData.tokenAddress) ? 
                parseEther(this.newSubscriptionData.amount.toString()) : 0n
            });
            break;
        }
        
        // Mettre à jour le statut de la transaction
        currentTx.status = 'success';
        currentTx.hash = hash;
        
        // Passer à la transaction suivante
        this.currentTransactionIndex++;
        
      } catch (error) {
        console.error('Erreur lors de la signature:', error);
        currentTx.status = 'error';
        currentTx.error = error.message;
      }
    },
    
    // Convertir l'intervalle en secondes
    calculateIntervalInSeconds(value, unit) {
      const val = parseInt(value)
      switch (unit) {
        case 'second': return val
        case 'minute': return val * 60
        case 'hour': return val * 3600
        case 'day': return val * 86400
        default: return val
      }
    },
    
    // Finaliser les transactions et rafraîchir les données
    finishTransactions() {
      this.closeTransactionsModal()
      this.loadSubscriptions()
    },
    
    // Supprimer un abonnement
    async deleteSubscription(subscription) {
      if (!this.isConnected || !subscription) return;
      
      try {
        // Appeler la fonction de suppression sur le contrat
        const hash = await this.walletClient.sendTransaction({
          account: this.isDevMode && this.privateKeyAccount ? 
            this.privateKeyAccount.address : 
            this.walletAddress,
          data: encodeFunctionData({
            abi: CFAbi,
            functionName: 'cancelSubscription',
            args: [subscription.id]
          }),
          to: CFContractAddress
        });
        
        // Fermer les détails et rafraîchir
        this.closeSubscriptionDetails();
        
        // Attendre confirmation et rafraîchir
        await this.publicClient.waitForTransactionReceipt({ hash });
        this.loadSubscriptions();
        
      } catch (error) {
        console.error('Erreur lors de la suppression:', error);
        this.error = 'Impossible de supprimer l\'abonnement';
      }
    }
  }
}
</script>

<style>
/* Styles globaux */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Inter', 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background-color: #f5f7fa;
  color: #333;
}

#app {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

/* Header */
.app-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 0;
  border-bottom: 1px solid #e1e4e8;
  margin-bottom: 40px;
}

.logo h1 {
  font-size: 28px;
  background: linear-gradient(90deg, #3b82f6, #10b981);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  font-weight: 700;
}

.wallet-connect .connect-btn {
  background: linear-gradient(90deg, #3b82f6, #10b981);
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.wallet-connect .connect-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.2);
}

.wallet-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.wallet-info .address {
  padding: 8px 12px;
  background-color: #f0f4f8;
  border-radius: 6px;
  font-size: 14px;
  font-family: monospace;
}

.wallet-info .disconnect-btn {
  background-color: transparent;
  border: 1px solid #e1e4e8;
  padding: 8px 16px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.wallet-info .disconnect-btn:hover {
  background-color: #f0f4f8;
}

/* Main content */
.main-content {
  margin-top: 20px;
}

.not-connected {
  text-align: center;
  padding: 100px 0;
  color: #64748b;
}

/* Subscription list */
.subscriptions-list {
  margin-bottom: 40px;
}

.subscriptions-list h2 {
  font-size: 24px;
  margin-bottom: 24px;
  color: #1e293b;
}

.loading-spinner {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px 0;
}

.spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3b82f6;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
  margin-bottom: 16px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.no-subscriptions {
  text-align: center;
  padding: 40px 0;
  color: #64748b;
}

.subscriptions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 24px;
}

.subscription-card {
  background-color: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
  overflow: hidden;
}

.subscription-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1);
}

.subscription-status {
  position: absolute;
  top: 12px;
  right: 12px;
  padding: 4px 8px;
  font-size: 12px;
  border-radius: 4px;
  background-color: #f1f5f9;
  color: #64748b;
}

.subscription-status.active {
  background-color: #dcfce7;
  color: #15803d;
}

.subscription-amount {
  margin-bottom: 16px;
}

.subscription-amount strong {
  font-size: 24px;
  color: #0f172a;
}

.subscription-amount span {
  font-size: 14px;
  color: #64748b;
  margin-left: 6px;
}

.subscription-interval, .subscription-next {
  color: #64748b;
  font-size: 14px;
  margin-bottom: 8px;
}

/* Create subscription button */
.create-subscription {
  display: flex;
  justify-content: center;
  margin-top: 60px;
}

.create-btn {
  background: linear-gradient(90deg, #3b82f6, #10b981);
  color: white;
  border: none;
  padding: 16px 32px;
  border-radius: 12px;
  font-size: 18px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 8px;
}

.create-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(59, 130, 246, 0.3);
}

.create-btn:active {
  transform: translateY(0);
}
</style>
