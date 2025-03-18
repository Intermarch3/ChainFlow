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
