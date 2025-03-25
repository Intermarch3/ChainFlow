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

#### Used addresses on sepolia network
link token sepolia address : `0x779877a7b0d9e8603169ddbd7836e478b4624789`
registrar sepolia address : `0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976`
registry sepolia address : `0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad`
ChainflowContract sepolia address : `0xaD63C0c9cAFeC5c9b4b14171899cf945b4765a44`
ChainflowPayment sepolia address : `0xEC4a3DBCef2d57B0eB861092d584AFCAa832c0FD`

#### TODO :
- [ ] need to calculate the min value to fund the upkeep with a simulate call in the front.
- [ ] boutton to cancel the subscription (with the upKeep cancel and withdraw of the upkeep funds on the registry contract)
- [ ] add max nb payment in the subscription

if want to cancel the subscription and withdraw the upkeep funds, need to call the `cancelSubscription` in chainflow contract and `cancelUpkeep(uint256 id)` + `withdrawFunds(uint256 id, address to)` in the chainlink registery contract.


#### steps to create a new subscription
```shell
//deploy chainflow payment contract
forge create src/Chainflow.sol:ChainflowPayment --private-key "" --legacy --broadcast -vvvvv --rpc-url https://sepolia.drpc.org


//deploy chainflow contract
forge create src/Chainflow.sol:ChainflowContract --private-key "" --legacy --broadcast -vvvvv --rpc-url https://sepolia.drpc.org --constructor-args "0x2A7c442BDf35346b9F43937696809f37Ad16a9c7" "0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976" "0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad" "0x779877a7b0d9e8603169ddbd7836e478b4624789"

//approve link to be spent by the chainflow contract
cast send 0x779877a7b0d9e8603169ddbd7836e478b4624789 "approve(address,uint256)" 0x27d517Bc2C440dcAFeaD6Ba502f47235Df508266 500000000000000000 --rpc-url https://sepolia.drpc.org --private-key ""

// new subscription
cast send 0x27d517Bc2C440dcAFeaD6Ba502f47235Df508266 "newSubscription(address,uint96,address,uint256,uint256,uint96)(uint256)" "0x0000000000000000000000000000000000000000" 2 "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC" 30 10 500000000000000000 --rpc-url https://sepolia.drpc.org --private-key "" --gas-price 1000100 --gas-limit 1000000
```

#### successfull transaction
ChainflowPayment deploy call succes : `0xb0ac85935cf6fa7c7abe5fa996a207960f7e3d18304af47c34480a3799603aae`
ChainflowContract deploy call succes : `0x326596ff887dd1fab892152f3607fed693851dcb13052686f9fee4ad942bb665`
setDedicatedMsgSender on ChainflowPayment + authorization for EOA to behave like ChainflowPayment contract call succes : `0x6ea4f2dae9192537d2daffc8bc80aa5c16b9abccda3037bdfffb4545b51ce2a4`
new subscription call succes : `0x61c0a703d5b632a38bb4a6753323eadc33a7b1219494fbb0cb8005153bc5b0fc`