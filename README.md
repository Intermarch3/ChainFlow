# ChainFlow
Abonnement récurrent blockchain utilisant l'EIP 7702 et Gelato

## Installation

```shell
cd app
npm install
```

```shell
cd contracts
forge install
```

## Usage

run app
```shell
npm run serve
```

run anvil node
```shell
anvil --hardfork prague
```

deploy contracts
```shell
forge create src/Counter.sol:TestContract --private-key "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d" --legacy --broadcast 
# this pk is an anvil dev account (add rpc url if needed)
```

Automate address used : `0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0`
OPS_PROXY_FACTORY address : `0x44bde1bccdD06119262f1fE441FBe7341EaaC185`


Commentaire gelato discord :
- contracts/lib/automate/contracts/integrations/AutomateReady.sol:18 wrong OPS_PROXY_FACTORY address (need to find the one from the deployment folder)
- https://docs.gelato.network/web3-services/web3-functions/understanding-web3-functions/create-a-web3-function-task/using-a-smart-contract#additional-info : link to example smart contract is broken
- https://docs.gelato.network/web3-services/web3-functions/understanding-web3-functions/create-a-web3-function-task/using-a-smart-contract#using-a-smart-contract : full code link broken too
- contracts/lib/automate/contracts/integrations/AutomateTaskCreator.sol:20 AutomateTaskCreator constructor call automate.taskTreasury() but this function doesn't exist anywhere in the codebase so any contract will fail to deploy