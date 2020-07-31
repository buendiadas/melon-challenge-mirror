const CompoundAdapter = artifacts.require('CompoundAdapter')
const ERC20 = artifacts.require('IERC20')
const Vault = artifacts.require('SimpleVault')
const config = require('../config')
const Comptroller = artifacts.require('IComptroller')

contract('CompoundAdapter', function (accounts) {
  let userVault
  let daiToken
  let cdaiToken
  let adapter
  let encodedParams
  let conf = config.mainnnet
    
  before('Deploying required contracts', async () => {
    userVault = await Vault.new()
    console.log('User Vault Address = ' + userVault.address)
    adapter = await CompoundAdapter.new()
    console.log('User adapter Address = ' + adapter.address)
    console.log(conf)
    daiToken = await ERC20.at(conf.DAI_COMPOUND)
    cdaiToken = await ERC20.at(conf.CDAI)
    await daiToken.transfer(userVault.address, web3.utils.toBN(1e18), {from: accounts[0]})
  })
  describe('Supplying assets from a new Vault', async () => {
    const supplyAmount = '100000000000'
    before('Call supplyAssets', async () => {
      encodedParams = web3.eth.abi.encodeParameters(
        ['address', 'address', 'uint256'],
        [
          conf.DAI_COMPOUND, // "path" from outgoing asset to incoming asset, including intermediaries
          conf.CDAI, // min incoming asset amount
          supplyAmount// exact outgoing asset amount
        ]
      );
      await userVault.addOwnedAsset(conf.DAI_COMPOUND)
      await userVault.callOnIntegration(adapter.address, 'supplyAssets(bytes)', encodedParams)
    });
    it('Should receive cDAI in exchange for DAI', async () => {
      const cDaiBalance = await cdaiToken.balanceOf(userVault.address)
      assert(cDaiBalance > 0);
    })
    it('Should include CDAI as a token', async () => {
      const isToken = await userVault.isOwnedAsset(conf.CDAI)
      assert(isToken, true, 'The token is not owned')
     })
  })
  describe('Redeeming assets', async () => {
    let initialTokenBalance
    let initialCTokenBalance
    const redeemAmount = 100

    before('Call redeem', async () => {
      initialTokenBalance = await daiToken.balanceOf(userVault.address)
      initialCTokenBalance = await cdaiToken.balanceOf(userVault.address)
      encodedParams = web3.eth.abi.encodeParameters(
        ['address', 'address', 'uint256'],
        [
          conf.DAI_COMPOUND, // "path" from outgoing asset to incoming asset, including intermediaries
          conf.CDAI, // min incoming asset amount
          redeemAmount// exact outgoing asset amount
        ]
      )
      await userVault.addOwnedAsset(conf.CDAI)
      await userVault.callOnIntegration(adapter.address, 'redeemAssets(bytes)', encodedParams)
    })
    it('cToken Balance should have been decreased by redeem_amount', async () => {
      const cTokenBalance = await cdaiToken.balanceOf(userVault.address)
      assert.equal(initialCTokenBalance - redeemAmount, cTokenBalance)
    })
    it('Token Balance should have been increased', async () => {
      const tokenBalance = await daiToken.balanceOf(userVault.address)
      assert(tokenBalance > initialTokenBalance, true)
    })
  })
  describe('Claiming COMP <- Will fail on Rinkeby', async () => {
    before('Call claimComp', async () => {
      encodedParams = web3.eth.abi.encodeParameters(
        ['address'],
        [
        conf.COMPTROLLER
        ]
      )
      await userVault.callOnIntegration(adapter.address, 'claimComp(bytes)', encodedParams)
    })
    it('Should include COMP as a token', async () => {
        const isToken = await userVault.isOwnedAsset(conf.COMP)
        assert(isToken, true, 'The token is not owned')
    })
  })
})
