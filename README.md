# ChainFlow
Abonnement récurrent blockchain utilisant l'EIP 7702 et chainlink automation

## Installation

```shell
cd app
npm install
```

```shell
cd contracts
forge install
npm install
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

wrapped eth sepolia address : `0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9`
need to calculate the min value to fund the upkeep with a simulate call in the front.

if want to cancel the subscription and withdraw the upkeep funds, need to call the `cancelSubscription` in chainflow contract and `cancelUpkeep(uint256 id)` + `withdrawFunds(uint256 id, address to)` in the chainlink registery contract.