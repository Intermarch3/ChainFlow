# ChainFlow

ChainFlow est une solution innovante permettant de gérer des abonnements sur les blockchain EVM.
Associé à Chainlink Automation, ChainFlow permet d'automatiser les transactions récurrentes pour la gestion des abonnements.

![homepage](./img/homepage.png)

## Fonctionnalités

- **Création d'abonnements multiples** : Chaque utilisateur peut créer plusieurs abonnements selon ses besoins.
- **Personnalisation des intervalles** : Choisissez des intervalles en secondes, heures, ou jours.
- **Support multi-devises** : Réalisez des transactions en Ethereum ou en tokens ERC20.
- **Automatisation des paiements** : Les transactions s'exécutent automatiquement grâce à Chainlink Automation.
- **Interface conviviale** : Un front-end intuitif permet de créer, consulter, mettre en pause ou supprimer vos abonnements en quelques clics.

## Installation

### Front-end

```bash
cd app/
npm install
npm run serve
```

### Contrats

```bash
cd contracts/
forge install
npm install
```

## Utilisation

1. Connectez votre wallet via l'interface front-end.
2. Créez un abonnement en définissant l'intervalle et le montant (en Ethereum ou en ERC20) et d'autres parametres.
3. Consultez la liste de vos abonnements actifs, mettez-les en pause ou supprimez-les directement depuis l'interface.

## Déploiement

### Addresses sur Sepolia
- LINK token : `0x779877a7b0d9e8603169ddbd7836e478b4624789`
- registrar : `0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976`
- registry : `0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad`

#### V1.0:
- ChainflowContract: `0x8a910720406Ce2109FAb303BdEbeD6a2f961D81E`
- ChainflowPayment: `0x973c5F90d1Fdd41c7befD3b2dcA48f73609A3b46`

## Contributions

Les contributions sont les bienvenues !  
Si vous souhaitez proposer des améliorations ou signaler des problèmes, merci de créer une issue ou de soumettre une pull request sur GitHub.
