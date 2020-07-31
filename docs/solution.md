# Melon Challenge -Solution

## Introduction

The repository includes two  Adapters: 

* [**Compound Adapter**](https://github.com/carlos-buendia/melon-challenge-mirror/tree/master/contracts/adapters/compound): The main integration of the solution. Integrates with Compound protocol, allowing to do some of the most important actions:
   * **Supply assets**: Providing an already existing in the vault `ERC20`, and exchanging it with a compount token (`cToken`).
   * **Redeem assets** : Specifying an amount of `cTokens` that want to be exchanged back to the underyingasset 
   * **Claim COMP**: to claim accrued interest from compound in `COMP` token
* [**Uniswap Adapter**](https://github.com/carlos-buendia/melon-challenge-mirror/blob/master/contracts/adapters/uniswap/UniswapV2Adapter.sol): Inspired on an existing integration which was created with the purpose of learning from an existing solution. It enables to exchange an existing `ERC20`, with another selected `ERC20`.


The proposed solution mainly focused on the first adapter (Compound). The technical details will be explained on a call. 


## CI
In order to run tests, both manually and automated, a ganache fork was provided for both Rinkeby and Mainnet. To easily set them up with an initial balance on the tokens which are necessary for testing, they were already funded with small amounts at an address accessible and public passphrase. *For obvious reasons this approach wouldn't be appropiated for a real money account* :😄.

Both can be accessed by using the following command

#### Rinkeby:

    npm start 

#### Mainnet

    npm run start-mainnet

## Tests

A small batery of tests was provided **for the Compound adapter**. In order to run them, make sure you have a ganache fork running as explained above, and type: 

    npm run test








