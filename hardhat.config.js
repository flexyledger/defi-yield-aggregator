require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x0000000000000000000000000000000000000000000000000000000000000001";
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "";
const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL || "";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        version: "0.8.24",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
            viaIR: true,
        },
    },
    networks: {
        hardhat: {
            forking: {
                url: MAINNET_RPC_URL || "https://eth-mainnet.g.alchemy.com/v2/demo",
                enabled: !!MAINNET_RPC_URL,
            },
        },
        localhost: {
            url: "http://127.0.0.1:8545",
        },
        sepolia: {
            url: SEPOLIA_RPC_URL,
            accounts: SEPOLIA_RPC_URL ? [PRIVATE_KEY] : [],
            chainId: 11155111,
        },
        mainnet: {
            url: MAINNET_RPC_URL,
            accounts: MAINNET_RPC_URL ? [PRIVATE_KEY] : [],
            chainId: 1,
        },
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS === "true",
        currency: "USD",
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts",
    },
};
