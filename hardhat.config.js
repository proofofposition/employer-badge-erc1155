require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require('dotenv').config({path: __dirname + '/.env'});
require('@openzeppelin/hardhat-upgrades');

const {BASE_GOERLI_API_URL, POLYGON_API_URL, POLYGON_MUMBAI_API_URL, OPTIMISM_API_URL, OPTIMISM_GOERLI_API_URL, SEPOLIA_API_URL, GOERLI_API_URL, PRIVATE_KEY, REPORT_GAS} = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        version: "0.8.17",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    networks: {
        goerli: {
            url: GOERLI_API_URL,
            accounts: [
                PRIVATE_KEY
            ]
        },
        optimism: {
            url: OPTIMISM_API_URL,
            accounts: [
                PRIVATE_KEY
            ]
        },
        optimism_goerli: {
            url: OPTIMISM_GOERLI_API_URL,
            accounts: [
                PRIVATE_KEY
            ]
        },
        sepolia: {
            timeout: 100000000,
            url: SEPOLIA_API_URL,
            accounts: [
                PRIVATE_KEY
            ]
        },
        polygon: {
            url: POLYGON_API_URL,
            accounts: [
                PRIVATE_KEY
            ]
        },
        polygon_mumbai: {
            url: POLYGON_MUMBAI_API_URL,
            accounts: [
                PRIVATE_KEY
            ]
        },
        base_goerli: {
            url: BASE_GOERLI_API_URL,
            accounts: [
                PRIVATE_KEY
            ]
        }
    },
    gasReporter: {
        enabled: !!(REPORT_GAS)
    }
};
