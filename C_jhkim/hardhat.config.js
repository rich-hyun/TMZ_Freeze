require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY || "573f640062bdeea5752371a25d0f9391b87d11b8574f4f0b9b27b541aa782b84";  // 0x로 시작

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: { optimizer: { enabled: true, runs: 200 } },
  },
  networks: {
    // 자체 PoA 네트워크
    jkk_tmz: {
      url: process.env.POA_RPC_URL || "https://jkk.mst2.site",  // http/https 맞춰 입력
      chainId: 7707,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      // gasPrice가 0인 네트워크면 아래 주석을 해제하고 0으로 설정
      gasPrice: 0
    },
  },
};
