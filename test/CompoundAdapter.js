  
//const advanceToBlock = require('./helpers/advanceToBlock')
//const { assertRevert } = require('./helpers/assertRevert')


const { toHex } = web3.utils;
const config = require('../config')
const CompoundAdapter = artifacts.require('CompoundAdapter')
const ERC20 = artifacts.require('IERC20')
const Vault = artifacts.require('SimpleVault');

contract('CompoundAdapter', function (accounts) {
    let userVault;
    let daiToken;
    let cdaiToken;
    let adapter;
    let encodedParams;
    

    before('Deploying required contracts', async () => {
        userVault = await Vault.new();
        console.log("User Vault Address = " + userVault.address)
        adapter = await CompoundAdapter.new();
        console.log(config);
        console.log("this is admin account" + config.rinkeby.DAI_COMPOUND)
        daiToken = await ERC20.at(config.rinkeby.DAI_COMPOUND);
        cdaiToken = await ERC20.at(config.rinkeby.CDAI);
        await daiToken.transfer(userVault.address, web3.utils.toBN(1e18), {from: accounts[0]});
    })
    beforeEach(async () => {
        let VaultBalance = await daiToken.balanceOf(userVault.address)
        let cdaiVaultBalance = await cdaiToken.balanceOf(userVault.address)
        console.log("ho ho ho! This is vault balance!!" + cdaiVaultBalance)
        console.log("ho ho ho! This is cDAI vault balance!!" + VaultBalance)
    })
    describe('Supplying assets from a new Vault', async () => {
        before('Call supplyAssets', async () => {
            encodedParams = web3.eth.abi.encodeParameters(
                ['address', 'address', 'uint256'],
                [
                config.rinkeby.DAI_COMPOUND, // "path" from outgoing asset to incoming asset, including intermediaries
                config.rinkeby.CDAI, // min incoming asset amount
                "100000000000"// exact outgoing asset amount
                ]
            );
            await userVault.addOwnedAsset(config.rinkeby.DAI_COMPOUND)
            await userVault.callOnIntegration(adapter.address, "supplyAssets(bytes)", encodedParams)
        });
        it('Should receive cDAI in exchange for DAI', async () => {
            const cDaiBalance = await cdaiToken.balanceOf(userVault.address);
            console.log(cDaiBalance);
            assert(cDaiBalance > 0);
        })
        it('Should include COMP as a token', async () => {
            const isCompToken = await userVault.isOwnedAsset(config.rinkeby.COMP);
            assert(isCompToken, true, "The token is not owned");
        })
    })
    describe('Redeeming assets', async () => {
        before('Call redeen', async () => {
            encodedParams = web3.eth.abi.encodeParameters(
                ['address', 'address', 'uint256'],
                [
                config.rinkeby.DAI_COMPOUND, // "path" from outgoing asset to incoming asset, including intermediaries
                config.rinkeby.CDAI, // min incoming asset amount
                "100"// exact outgoing asset amount
                ]
            );
            console.log(encodedParams)
            await userVault.addOwnedAsset(config.rinkeby.CDAI)
            await userVault.callOnIntegration(adapter.address, "redeemAssets(bytes)", encodedParams)
        });
        it('Vault should include cDAI as an asset', async () => {
            //const isToken = await userVault.isOwnedAsset(config.rinkeby.CDAI);
            //assert(isToken, true, "The token is not owned");
        })
    })
})
