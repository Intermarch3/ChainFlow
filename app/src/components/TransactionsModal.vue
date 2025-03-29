<template>
  <div class="modal-overlay">
    <div class="modal-container">
      <div class="modal-header">
        <h2>Signature des transactions</h2>
        <button @click="close" class="close-btn" :disabled="isProcessing">&times;</button>
      </div>
      
      <div class="modal-body">
        <div class="transactions-list">
          <div 
            v-for="transaction in transactions" 
            :key="transaction.id" 
            class="transaction-item"
            :class="{ 
              'completed': isCompletedTransaction(transaction),
              'active': !oneTxIsProcessing() && isCurrentTransaction(transaction),
              'error': hasError(transaction)
            }"
          >
            <!-- Indicateur de statut -->
            <div class="transaction-status">
              <div v-if="transactionIsProcessing(transaction)" class="status-spinner"></div>
              <div v-else class="status-icon">
                <span v-if="isCompletedTransaction(transaction)" class="success-icon">✓</span>
                <span v-else-if="hasError(transaction)" class="error-icon">⨯</span>
                <span v-else class="pending-icon">•</span>
              </div>
            </div>
            
            <!-- Informations de la transaction -->
            <div class="transaction-info">
              <div class="transaction-name">{{ transaction.name }}</div>
              <div class="transaction-description">{{ transaction.description }}</div>
              
              <!-- Message d'erreur si applicable -->
              <div v-if="hasError(transaction)" class="transaction-error">
                {{ transaction.error }}
              </div>
              
              <!-- Lien vers Etherscan si la transaction est confirmée -->
              <div v-if="transaction.hash && transaction.hash !== '0x'" class="transaction-hash">
                <a :href="getExplorerLink(transaction.hash)" target="_blank" class="hash-link">
                  Voir la transaction
                  <span class="external-icon">↗</span>
                </a>
              </div>
            </div>
            
            <!-- Bouton de signature -->
            <div class="transaction-action">
              <button 
                v-if="isCurrentTransaction(transaction) && !oneTxIsProcessing()"
                @click="sign()"
                class="sign-btn"
              >
                Signer
              </button>
              <button 
                v-if="hasError(transaction)" 
                @click="retry(transaction)"
                class="retry-btn"
              >
                Réessayer
              </button>
            </div>
          </div>
        </div>
        
        <!-- Progression globale -->
        <div class="progress-container">
          <div class="progress-bar">
            <div 
              class="progress-fill"
              :style="{ width: `${progressPercentage}%` }"
            ></div>
          </div>
          <div class="progress-text">
            {{ completedTransactions }} sur {{ transactions.length }} transactions
          </div>
        </div>
        
        <!-- Instructions -->
        <div class="instructions">
          <p v-if="isAllCompleted">
            Toutes les transactions ont été signées avec succès. Votre abonnement est maintenant actif !
          </p>
          <p v-else-if="completedTransactions === 0">
            Veuillez signer chaque transaction pour configurer votre abonnement. Vous devrez confirmer chaque transaction dans votre portefeuille.
          </p>
          <p v-else>
            Continuez de signer les transactions restantes pour finaliser votre abonnement.
          </p>
        </div>
      </div>
      
      <div class="modal-footer">
        <button 
          v-if="hasErrors" 
          @click="close" 
          class="cancel-btn"
        >
          Annuler
        </button>
        
        <button 
          v-if="isAllCompleted"
          @click="finish" 
          class="finish-btn"
        >
          Terminer
        </button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'TransactionsModal',
  props: {
    transactions: {
      type: Array,
      required: true
    }
  },
  data() {
    return {
      isProcessing: false
    }
  },
  computed: {
    currentTransactionIndex() {
      return this.transactions.findIndex(tx => tx.status === 'pending')
    },
    
    completedTransactions() {
      return this.transactions.filter(tx => tx.status === 'success').length
    },
    
    progressPercentage() {
      return (this.completedTransactions / this.transactions.length) * 100
    },
    
    isAllCompleted() {
      return this.completedTransactions === this.transactions.length
    },
    
    hasErrors() {
      return this.transactions.some(tx => tx.status === 'error')
    }
  },
  methods: {
    close() {
      if (this.isProcessing) return
      this.$emit('close')
    },
    
    finish() {
      this.$emit('finish')
    },

    transactionIsProcessing(transaction) {
      return transaction.status === 'processing'
    },

    oneTxIsProcessing() {
      return this.transactions.some(tx => tx.status === 'processing')
    },
    
    sign() {
      if (this.currentTransactionIndex < 0 || this.isProcessing) return
      const txIdx = this.currentTransactionIndex
      
      this.isProcessing = true
      this.$emit('sign')
      
      this.isProcessing = false
    },
    
    retry(transaction) {
      // Trouver l'index de la transaction en échec
      const index = this.transactions.findIndex(tx => tx.id === transaction.id)
      
      if (index >= 0) {
        // Réinitialiser le statut de la transaction
        this.$set(this.transactions[index], 'status', 'pending')
        this.$set(this.transactions[index], 'error', null)
        
        // Réinitialiser toutes les transactions suivantes
        for (let i = index + 1; i < this.transactions.length; i++) {
          this.$set(this.transactions[i], 'status', 'pending')
          this.$set(this.transactions[i], 'hash', null)
          this.$set(this.transactions[i], 'error', null)
        }
        
        // Déclencher la signature
        this.sign()
      }
    },
    
    isCurrentTransaction(transaction) {
      return this.currentTransactionIndex >= 0 && 
             transaction.id === this.transactions[this.currentTransactionIndex].id
    },
    
    isCompletedTransaction(transaction) {
      return transaction.status === 'success'
    },
    
    hasError(transaction) {
      return transaction.status === 'error'
    },
    
    getExplorerLink(hash) {
      // Sur Sepolia
      return `https://sepolia.etherscan.io/tx/${hash}`
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
  width: 650px;
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

.close-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
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
  justify-content: flex-end;
  gap: 10px;
}

.transactions-list {
  margin-bottom: 24px;
}

.transaction-item {
  display: flex;
  align-items: center;
  padding: 16px;
  margin-bottom: 12px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  transition: all 0.3s;
}

.transaction-item.active {
  border-color: #3b82f6;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.1);
}

.transaction-item.completed {
  border-color: #10b981;
  background-color: #f0fdf4;
}

.transaction-item.error {
  border-color: #ef4444;
  background-color: #fef2f2;
}

.transaction-status {
  flex: 0 0 40px;
  display: flex;
  justify-content: center;
  align-items: center;
}

.status-icon {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: bold;
}

.status-spinner {
  width: 24px;
  height: 24px;
  border: 3px solid #f3f3f3;
  border-top: 3px solid #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.success-icon {
  color: #10b981;
  font-size: 30px;
  font-weight: bold;
}

.error-icon {
  color: #ef4444;
  font-size: 30px;
  font-weight: bold;
}

.pending-icon {
  color: #94a3b8;
  font-size: 24px;
}

.transaction-info {
  flex: 1;
  padding: 0 16px;
}

.transaction-name {
  font-weight: 600;
  margin-bottom: 4px;
  color: #0f172a;
}

.transaction-description {
  font-size: 14px;
  color: #64748b;
  margin-bottom: 8px;
}

.transaction-error {
  color: #dc2626;
  font-size: 14px;
  margin-top: 4px;
  background-color: #fee2e2;
  padding: 6px 10px;
  border-radius: 4px;
  white-space: nowrap;
  overflow-x: auto;
  scrollbar-width: none; /* Firefox */
  -ms-overflow-style: none;
}

.transaction-hash {
  margin-top: 8px;
}

.hash-link {
  color: #3b82f6;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  font-size: 14px;
}

.hash-link:hover {
  text-decoration: underline;
}

.external-icon {
  margin-left: 4px;
}

.transaction-action {
  flex: 0 0 100px;
  text-align: right;
}

.sign-btn, .retry-btn {
  padding: 8px 16px;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
  border: none;
}

.sign-btn {
  background-color: #3b82f6;
  color: white;
}

.sign-btn:hover {
  background-color: #2563eb;
}

.retry-btn {
  background-color: #f1f5f9;
  color: #334155;
}

.retry-btn:hover {
  background-color: #e2e8f0;
}

.progress-container {
  margin: 24px 0;
}

.progress-bar {
  height: 8px;
  background-color: #f1f5f9;
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 8px;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #3b82f6, #10b981);
  border-radius: 4px;
  transition: width 0.3s ease;
}

.progress-text {
  font-size: 14px;
  color: #64748b;
  text-align: right;
}

.instructions {
  background-color: #f8fafc;
  border-radius: 8px;
  padding: 16px;
  margin-top: 24px;
}

.instructions p {
  color: #334155;
  font-size: 14px;
  line-height: 1.5;
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

.cancel-btn:hover {
  background-color: #e2e8f0;
}

.finish-btn {
  background: linear-gradient(90deg, #3b82f6, #10b981);
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.finish-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.2);
}
</style>