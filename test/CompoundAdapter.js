  
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
        console.log("User adapter Address = " + adapter.address)
        console.log(config);
        daiToken = await ERC20.at(config.rinkeby.DAI_COMPOUND);
        cdaiToken = await ERC20.at(config.rinkeby.CDAI);
        await daiToken.transfer(userVault.address, web3.utils.toBN(1e18), {from: accounts[0]});
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
            assert(cDaiBalance > 0);
        })
        it('Should include CDAI as a token', async () => {
            const isToken = await userVault.isOwnedAsset(config.rinkeby.CDAI);
            assert(isToken, true, "The token is not owned");
        })
        it('Should include COMP as a token', async () => {
            const isToken = await userVault.isOwnedAsset(config.rinkeby.COMP);
            assert(isToken, false, "The token is not owned");
        })
        
    })
    describe('Redeeming assets', async () => {
        let initialTokenBalance;
        let initialCTokenBalance;
        const redeem_amount = 100;

        before('Call redeem', async () => {
            initialTokenBalance = await daiToken.balanceOf(userVault.address);
            initialCTokenBalance = await cdaiToken.balanceOf(userVault.address);
            encodedParams = web3.eth.abi.encodeParameters(
                ['address', 'address', 'uint256'],
                [
                config.rinkeby.DAI_COMPOUND, // "path" from outgoing asset to incoming asset, including intermediaries
                config.rinkeby.CDAI, // min incoming asset amount
                redeem_amount// exact outgoing asset amount
                ]
            );
            await userVault.addOwnedAsset(config.rinkeby.CDAI)
            await userVault.callOnIntegration(adapter.address, "redeemAssets(bytes)", encodedParams)
            
        });
        it('cToken Balance should have been decreased by redeem_amount', async () => {
            const cTokenBalance = await cdaiToken.balanceOf(userVault.address);
            assert.equal(initialCTokenBalance - redeem_amount, cTokenBalance)
        })
        it('Token Balance should have been increased', async () => {
            const tokenBalance = await daiToken.balanceOf(userVault.address);
            assert(tokenBalance > initialTokenBalance);
        })
    })
})
