const HDWalletProvider = require('truffle-hdwallet-provider')
const mnemonic = 'brand insane federal bargain nice pilot recall zero disagree action arrive hint'

module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '1234',
      gas: 6721975,
      gasPrice: 1

    },
    rinkeby: {
      host: 'localhost',
      port: 8545,
      network_id: 4,
      gas: 6721975,
      gasPrice: 4
    },
    rinkeby_infura: {
      provider: function () {
        return new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/xzValG5J1iIcK29rdTFK')
      },
      network_id: 4
    }
  },
  mocha: {
    reporter: 'eth-gas-reporter',
    reporterOptions : {
      currency: 'USD',
      gasPrice: 21
    }
  },
  // Configure your compilers
  compilers: {
    solc: {
      version: "0.6.6",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
      //  optimizer: {
      //    enabled: false,
      //    runs: 200
      //  },
      //  evmVersion: "byzantium"
      // }
    }
  }
}
