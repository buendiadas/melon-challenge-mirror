👉🏻 [Link to solution description](https://github.com/carlos-buendia/melon-challenge-mirror/blob/master/docs/solution.md) 👈🏻 



# Melon Coding Challenge




## Background

Melon has three kinds of shared plugins (external contracts) that each fund can use to extend their functionality:

- "Fees" that fund managers charge for their services (e.g., a rolling management fee, performance fee)
- "Policies" that protect a fund against compliance (e.g., an investor whitelist) and risk (e.g., an asset whitelist)
- "Integration adapters" that allow external calls to third party DeFi protocols (e.g., lend on Compound, takeOrder on 0x)

This coding challenge will deal only with the 3rd category (integration adapters). Essentially, a fund manager builds positions for their fund by trading/loaning/etc the fund's assets via integration adapters, which plug in to its Vault.

Some examples of current and future adapters in melon are:
- `KyberAdapter`
- `OasisDexAdapter`
- `AirswapAdapter`
- `UniswapAdapter`
- `ZeroExV3Adapter`
- `CompoundAdapter` (https://compound.finance/)
- `ChaiAdapter` (https://chai.money/)

## Challenge

Write an integration adapter contract of your choosing.

It can either integrate actions directly from a DeFi protocol of your choosing that isn't listed above (e.g., Balancer, Bancor, Maker), or can perform a set of arbitrary interactions with various protocols to some net positive result.

### Notes

The current Melon Protocol contracts are in flux and a bit complicated, so rather than using the "live" system, we've written a simple vault + adapter structure for this coding challenge.

Still, it might be helpful (not required) to reference the old version of the protocol, as well as the in-progress version:
- Old/current (v1): https://github.com/melonproject/protocol/tree/master
- New (in-progress): https://github.com/melonproject/protocol/tree/develop

The contracts in the boilerplate provided (`contracts/`) are:
- `SimpleVault.sol`: (no need to edit) a simple vault structure that calls your adapter via a low-level `.call()`.
- `MyAdapter.sol`: your adapter, where the bulk of work will be done. Please change the filename along with the contract name.
- `IntegrationSignatures.sol`: this file should contain a "selector" constant for each method on your adapter that should be callable via `SimpleVault.callOnIntegration()`. You'll need these in `MyAdapter.parseOutgoingAssets()`.
- `IAdapter.sol`: (no need to edit) a simple interface inherited by the adapter
- `IERC20.sol`: a simple interface for interacting with ERC20 tokens

In this challenge, `SimpleVault` calls its adapters via the low-level `.call()`. The current Melon Vault actually calls its adapters via a `delegatecall()`, but we're considering changing this, in part because this opens up a number of interesting use cases for using contract storage on the adapter. Feel free to experiment with state if you have a need for it.

### Requirements

- Read and work off of the boilerplate contracts in `contracts/`.
- You can use any solidity version, 0.6.0 or greater. Set the compiler version in `truffle-config.js`.
- If you use any third party libraries, e.g., OpenZeppelin, use a package manager to install them.
- At the end of any single transaction, all unused assets and all incoming assets need to be transferred back to `SimpleVault`.
- In Melon, ETH is not used as a fund asset, only WETH. Your adapter can transact with external protocols with and receive ETH, but it must be wrapped as WETH before returning to `SimpleVault`.
- The contracts must all compile with no errors using `truffle compile`.

### Bonuses

Please don't feel like you need to do any/all of these things, they are just suggestions if you feel like the core challenge is too easy :P

- Instead of a simple focus on a previous idea from a hackathon that you think would make a cool integration for Melon funds
- Write a test (using `truffle test` or jest) for `SimpleVault`'s calls to your adapter
- Read through the boilerplate code and point out our mistakes :) This was written in an afternoon, so they probably exist.

## Instructions

1. Fork this repo
2. Install Truffle globally: `npm install -g truffle`
3. Go go go!
