<template>
  <div class="modal-overlay" @click.self="close">
    <div class="modal-container">
      <div class="modal-header">
        <h2>Détails de l'abonnement</h2>
        <div class="detail-status" :class="{ 'active': subscription.active, 'paused': subscription.paused }">
          {{ subscription.active ? (subscription.paused ? 'Paused' : 'Active') : 'Inactive' }}
        </div>
        <button @click="close" class="close-btn">&times;</button>
      </div>
      
      <div class="modal-body">
        <div v-if="subscription" class="subscription-details">
          
          <!-- Détails principaux -->
          <div class="detail-row">
            <div class="detail-label">ID:</div>
            <div class="detail-value id">{{ subscription.id }}</div>
          </div>
          
          <div class="detail-row">
            <div class="detail-label">Montant:</div>
            <div class="detail-value">{{ formatAmount(subscription.amount) }} {{ tokenSymbol }}</div>
          </div>
          
          <div class="detail-row">
            <div class="detail-label">Récurrence:</div>
            <div class="detail-value">Tous les {{ formatInterval(subscription.interval) }}</div>
          </div>
          
          <div class="detail-row">
            <div class="detail-label">Adresse du token:</div>
            <div class="detail-value address">{{ tokenAddress }}</div>
          </div>
          
          <div class="detail-row">
            <div class="detail-label">Bénéficiaire:</div>
            <div class="detail-value address">{{ subscription.to }}</div>
          </div>
          
          <div class="detail-row">
            <div class="detail-label">Prochain paiement:</div>
            <div class="detail-value">{{ formatDate(subscription.nextPayment) }}</div>
          </div>
          
          <div class="detail-row">
            <div class="detail-label">Chainlink upKeep Id:</div>
            <div class="detail-value address">{{ subscription.upKeepId || 'Error' }}</div>
          </div>
          
          <div class="detail-row">
            <div class="detail-label">Paiements effectués:</div>
            <div class="detail-value">{{ subscription.nbPaymentsDone || '0' }} / {{ subscription.nbPayments }}</div>
          </div>
          
          <!-- Lien vers l'explorateur de blocs -->
          <div class="blockchain-links">
            <a :href="getExplorerLink()" target="_blank" class="explorer-link">
              Voir sur l'explorateur de blocs
              <span class="external-icon">↗</span>
            </a>
          </div>
        </div>
      </div>
      
      <div class="modal-footer">
        <button v-if="!subscription.paused" @click="confirmePause" class="cancel-btn">Pause cette abonnement</button>
        <button v-else @click="confirmeResume" class="cancel-btn">Réactiver cette abonnement</button>
        <button @click="confirmDelete" class="delete-btn">
          Supprimer cette abonnement
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { formatEther } from 'viem'
import { CFContractAddress } from '@/contracts/ChainflowContract'

// Adresse de token natif (ETH)
const NATIVE_TOKEN_ADDRESS = "0x0000000000000000000000000000000000000000"

export default {
  name: 'SubscriptionDetailsModal',
  props: {
    subscription: {
      type: Object,
      required: true
    }
  },
  computed: {
    tokenSymbol() {
      return this.isNativeToken(this.subscription.token) ? 'ETH' : 'ERC-20'
    },
    tokenAddress() {
      if (this.isNativeToken(this.subscription.token)) {
        return 'ETH (TOKEN NATIF)'
      }
      return this.subscription.token
    }
  },
  methods: {
    close() {
      this.$emit('close')
    },
    
    confirmDelete() {
      if (confirm('Êtes-vous sûr de vouloir supprimer cette subscription ? Cette action est irréversible.')) {
        this.$emit('delete', this.subscription)
      }
    },

    confirmePause() {
      if (confirm('Êtes-vous sûr de vouloir mettre cette subscription en pause ?')) {
        this.$emit('pause', this.subscription)
      }
    },

    confirmeResume() {
      if (confirm('Êtes-vous sûr de vouloir réactiver cette subscription ?')) {
        this.$emit('resume', this.subscription)
      }
    },
    
    formatAmount(amount) {
      return formatEther(amount)
    },
    
    isNativeToken(tokenAddress) {
      return tokenAddress.toLowerCase() === NATIVE_TOKEN_ADDRESS.toLowerCase()
    },
    
    formatInterval(intervalInSeconds) {
      const seconds = typeof intervalInSeconds === 'bigint' ? 
        Number(intervalInSeconds) : Number(intervalInSeconds);
      if (seconds < 60) {
        return `${seconds} secondes`
      } else if (seconds < 3600) {
        const minutes = Math.floor(seconds / 60)
        return `${minutes} minute${minutes > 1 ? 's' : ''}`
      } else if (seconds < 86400) {
        const hours = Math.floor(seconds / 3600)
        return `${hours} heure${hours > 1 ? 's' : ''}`
      } else {
        const days = Math.floor(seconds / 86400)
        return `${days} jour${days > 1 ? 's' : ''}`
      }
    },

    // get event from subscription creation and return the creation date
    async getCreationDate(subscription) {
      try {
        const events = await this.$store.dispatch('getEvent', {
          contractAddress: CFContractAddress,
          eventName: 'ChainflowNewSubscription',
          filter: { from: subscription.from }
        })
        for (const event of events) {
          if (event.args.subscriptionId === subscription.id) {
            return event.timestamp
          }
        }
        console.log('No event found for this subscription')
        return null
      } catch (error) {
        console.error('Error fetching creation date:', error)
        return null
      }
    },
    
    formatDate(timestamp) {
      const date = new Date(Number(timestamp) * 1000)
      return date.toLocaleString()
    },
    
    getExplorerLink(id = CFContractAddress) {
      // Sur Sepolia
      return `https://sepolia.etherscan.io/address/${id}?from=${this.subscription.from}`
    }
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 999;
}

.modal-container {
  background-color: white;
  width: 560px;
  max-width: 90%;
  max-height: 90vh;
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.modal-header {
  padding: 20px;
  border-bottom: 1px solid #e1e4e8;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-header h2 {
  font-size: 20px;
  color: #0f172a;
  margin: 0;
}

.close-btn {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #64748b;
}

.modal-body {
  padding: 20px;
  overflow-y: auto;
  max-height: calc(90vh - 150px);
}

.modal-footer {
  padding: 15px 20px;
  border-top: 1px solid #e1e4e8;
  display: flex;
  justify-content: space-between;
  gap: 10px;
}

.subscription-details {
  position: relative;
  padding-top: 10px;
}

.detail-status {
  position: relative;
  right: 0;
  padding: 6px 12px;
  font-size: 14px;
  border-radius: 6px;
  background-color: #f1f5f9;
  color: #64748b;
  font-weight: 600;
}

.detail-status.active {
  background-color: #dcfce7;
  color: #15803d;
}

.detail-status.paused {
  background-color: #fefcbf!important;
  color: #ca8a04!important;
}

.detail-row {
  display: flex;
  margin-bottom: 16px;
  border-bottom: 1px solid #f1f5f9;
  padding-bottom: 12px;
}

.detail-label {
  flex: 0 0 150px;
  color: #64748b;
  font-size: 14px;
  font-weight: 500;
}

.detail-value {
  flex: 1;
  font-size: 16px;
  color: #1e293b;
  word-break: break-word;
}

.detail-value.address, .detail-value.id {
  font-family: monospace;
  font-size: 14px;
  background-color: #f8fafc;
  padding: 4px 8px;
  border-radius: 4px;
  white-space: nowrap;
  overflow-x: auto;
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none;
}

.blockchain-links {
  margin-top: 24px;
  padding-top: 16px;
  border-top: 1px solid #e2e8f0;
}

.explorer-link {
  display: inline-flex;
  align-items: center;
  text-decoration: none;
  color: #3b82f6;
  font-size: 14px;
  transition: all 0.2s;
}

.explorer-link:hover {
  color: #1d4ed8;
  text-decoration: underline;
}

.external-icon {
  margin-left: 6px;
}

.cancel-btn {
  background-color: #fefcbf;
  color: #ca8a04;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.2s;
}

.cancel-btn:hover {
  background-color: #e2e8f0;
}

.delete-btn {
  background-color: #fee2e2;
  color: #b91c1c;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.2s;
}

.delete-btn:hover {
  background-color: #fecaca;
}
</style>