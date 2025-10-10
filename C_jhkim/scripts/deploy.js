const hre = require("hardhat");

async function main() {
  const F = await hre.ethers.getContractFactory("FrozenClockSBT");
  const c = await F.deploy();
  await c.waitForDeployment();
  console.log("FrozenClockSBT deployed to:", await c.getAddress());
}

main().catch((e) => { console.error(e); process.exit(1); });
