<template>
  <div class="modal-overlay" @click.self="close">
    <div class="modal-container">
      <div class="modal-header">
        <h2>Créer une subscription</h2>
        <button @click="close" class="close-btn">&times;</button>
      </div>
      
      <div class="modal-body">
        <form @submit.prevent="submitForm">
          <!-- Intervalles -->
          <div class="form-group">
            <label>Intervalle entre paiements</label>
            <div class="form-row">
              <input 
                v-model="form.intervalValue" 
                type="number" 
                min="1" 
                class="form-control" 
                required
              />
              <select v-model="form.intervalUnit" class="form-control">
                <option value="second">Secondes</option>
                <option value="minute">Minutes</option>
                <option value="hour">Heures</option>
                <option value="day">Jours</option>
              </select>
            </div>
          </div>
          
          <!-- Montant -->
          <div class="form-group">
            <label>Montant par paiement</label>
            <input 
              v-model="form.amount" 
              type="number" 
              step="0.000001" 
              min="0" 
              class="form-control" 
              required
            />
          </div>
          
          <!-- Type de token -->
          <div class="form-group">
            <label>Type de token</label>
            <div class="token-selector">
              <div 
                class="token-option" 
                :class="{ 'selected': form.tokenType === 'ETH' }" 
                @click="selectToken('ETH')"
              >
                ETH
              </div>
              <div 
                class="token-option" 
                :class="{ 'selected': form.tokenType === 'ERC20' }" 
                @click="selectToken('ERC20')"
              >
                ERC-20
              </div>
            </div>
            
            <!-- Adresse ERC-20 (conditionnellement affiché) -->
            <div v-if="form.tokenType === 'ERC20'" class="form-group">
              <label>Adresse du token ERC-20</label>
              <input 
                v-model="form.tokenAddress" 
                type="text" 
                placeholder="0x..."
                class="form-control"
                required
              />
            </div>
          </div>
          
          <!-- Délai avant premier paiement -->
          <div class="form-group">
            <label>Délai avant le premier paiement (secondes)</label>
            <input 
              v-model="form.startDelay" 
              type="number" 
              min="0" 
              class="form-control" 
              required
            />
          </div>
          
          <!-- Adresse destinataire -->
          <div class="form-group">
            <label>Adresse du destinataire</label>
            <input 
              v-model="form.recipientAddress" 
              type="text" 
              placeholder="0x..." 
              class="form-control" 
              required
            />
          </div>
          
          <!-- Nombre total de paiements -->
          <div class="form-group">
            <label>Nombre total de paiements</label>
            <input 
              v-model="form.paymentsCount" 
              type="number" 
              min="1" 
              class="form-control" 
              required
            />
          </div>
          
          <!-- Estimation des coûts -->
          <div class="cost-estimation">
            <h3>Estimation des coûts Chainlink</h3>
            <button 
              type="button" 
              @click="estimateCosts" 
              class="estimate-btn" 
              :disabled="isEstimating"
            >
              {{ isEstimating ? 'Estimation...' : 'Estimer le coût' }}
            </button>
            
            <div v-if="estimatedCosts" class="estimation-results">
              <div class="estimation-item">
                <span>Coût par paiement:</span>
                <span>{{ estimatedCosts.perPayment }} LINK</span>
              </div>
              <div class="estimation-item">
                <span>Estimation totale:</span>
                <span>{{ estimatedCosts.total }} LINK</span>
              </div>
              
              <div class="form-group">
                <label>Montant LINK à utiliser</label>
                <input 
                  v-model="form.linkAmount" 
                  type="number" 
                  step="0.01" 
                  min="1" 
                  class="form-control" 
                  required
                />
              </div>
            </div>
          </div>
        </form>
      </div>
      
      <div class="modal-footer">
        <button @click="close" class="cancel-btn">Annuler</button>
        <button 
          @click="confirm" 
          class="confirm-btn" 
          :disabled="!isFormValid || isEstimating"
        >
          Confirmer
        </button>
      </div>
    </div>
  </div>
</template>

<script>
const NATIVE_TOKEN_ADDRESS = "0x0000000000000000000000000000000000000000"

export default {
  name: 'SubscriptionModal',
  data() {
    return {
      form: {
        intervalValue: 1,
        intervalUnit: 'minute',
        amount: 0.01,
        tokenType: 'ETH',
        tokenAddress: NATIVE_TOKEN_ADDRESS,
        startDelay: 60,
        recipientAddress: '',
        paymentsCount: 10,
        linkAmount: 1
      },
      isEstimating: false,
      estimatedCosts: null
    }
  },
  computed: {
    isFormValid() {
      const { 
        intervalValue, 
        amount, 
        tokenType, 
        tokenAddress, 
        startDelay, 
        recipientAddress, 
        paymentsCount, 
        linkAmount 
      } = this.form
      
      // Vérification minimale
      if (!intervalValue || !amount || !startDelay || !paymentsCount) return false
      if (!recipientAddress || !recipientAddress.startsWith('0x')) return false
      
      // Si c'est un token ERC-20, vérifier l'adresse
      if (tokenType === 'ERC20' && (!tokenAddress || !tokenAddress.startsWith('0x'))) return false
      
      // S'il y a une estimation, vérifier que le montant LINK est spécifié
      if (this.estimatedCosts && !linkAmount) return false
      
      return true
    }
  },
  methods: {
    close() {
      this.$emit('close')
    },
    
    selectToken(type) {
      this.form.tokenType = type
      this.form.tokenAddress = type === 'ETH' ? NATIVE_TOKEN_ADDRESS : ''
      // Réinitialiser l'estimation quand le type change
      this.estimatedCosts = null
    },
    
    async estimateCosts() {
      this.isEstimating = true
      
      try {
        // Simulation d'une estimation - dans un vrai cas cela ferait une requête
        await new Promise(resolve => setTimeout(resolve, 1500))
        
        // Calcul basé sur le nombre de paiements et l'intervalle
        const baseCost = 0.1 // LINK par paiement
        const interval = parseInt(this.form.intervalValue)
        const frequencyMultiplier = this.getIntervalMultiplier()
        
        // Plus l'intervalle est court, plus le coût est élevé
        const perPaymentCost = baseCost * (1 / frequencyMultiplier)
        
        // Calcul du total
        const totalCost = perPaymentCost * this.form.paymentsCount
        
        this.estimatedCosts = {
          perPayment: perPaymentCost.toFixed(4),
          total: totalCost.toFixed(4)
        }
        
        // Suggérer le montant total comme valeur par défaut
        this.form.linkAmount = Math.ceil(totalCost * 10) / 10 // Arrondi à la décimale supérieure
        
      } catch (error) {
        console.error('Erreur lors de l\'estimation:', error)
      } finally {
        this.isEstimating = false
      }
    },
    
    getIntervalMultiplier() {
      switch (this.form.intervalUnit) {
        case 'second': return 0.1
        case 'minute': return 1
        case 'hour': return 12
        case 'day': return 288
        default: return 1
      }
    },
    
    confirm() {
      if (this.isFormValid) {
        // Transformer les données en format attendu par le parent
        const subscriptionData = {
          intervalValue: parseInt(this.form.intervalValue),
          intervalUnit: this.form.intervalUnit,
          amount: this.form.amount,
          tokenAddress: this.form.tokenAddress,
          tokenType: this.form.tokenType,
          tokenSymbol: this.form.tokenType === 'ETH' ? 'ETH' : 'ERC-20',
          startDelay: parseInt(this.form.startDelay),
          recipientAddress: this.form.recipientAddress,
          paymentsCount: parseInt(this.form.paymentsCount),
          linkAmount: this.form.linkAmount
        }
        
        this.$emit('confirm', subscriptionData)
      }
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
  width: 500px;
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
  max-height: calc(90vh - 130px);
}

.modal-footer {
  padding: 15px 20px;
  border-top: 1px solid #e1e4e8;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 500;
  color: #334155;
  font-size: 14px;
}

.form-control {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  font-size: 14px;
  transition: border-color 0.2s;
}

.form-control:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.1);
}

.form-row {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 10px;
}

.token-selector {
  display: flex;
  gap: 10px;
  margin-bottom: 16px;
}

.token-option {
  flex: 1;
  padding: 12px;
  text-align: center;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}

.token-option.selected {
  background-color: #eff6ff;
  border-color: #3b82f6;
  color: #1e40af;
  font-weight: 600;
}

.cost-estimation {
  background-color: #f8fafc;
  padding: 16px;
  border-radius: 8px;
  margin-top: 24px;
}

.cost-estimation h3 {
  font-size: 16px;
  color: #334155;
  margin-bottom: 12px;
}

.estimate-btn {
  background-color: #3b82f6;
  color: white;
  border: none;
  padding: 10px 16px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  width: 100%;
}

.estimate-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.estimation-results {
  margin-top: 16px;
  padding-top: 16px;
  border-top: 1px solid #e2e8f0;
}

.estimation-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
  font-size: 14px;
}

.confirm-btn {
  background: linear-gradient(90deg, #3b82f6, #10b981);
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.confirm-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.cancel-btn {
  background-color: #f1f5f9;
  color: #334155;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
}

.confirm-btn:hover:not(:disabled), 
.cancel-btn:hover {
  transform: translateY(-2px);
}
</style>