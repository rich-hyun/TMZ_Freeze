const hre = require("hardhat");

const CONTRACT = process.env.SBT_ADDRESS || "0xYourDeployedAddress";

async function main() {
  const sbt = await hre.ethers.getContractAt("FrozenClockSBT", CONTRACT);

  const to   = process.env.RECIPIENT   || "0xRecipientWallet";
  const ext  = process.env.EXT_ID      || "KB-30";
  const name = process.env.HOLDER_NAME || "홍길동";
  const date = process.env.DATE        || "2025.09.25";

  // 예측 tokenId (static call)
  const predicted = await sbt.mint.staticCall(to, ext, name, date);

  const tx = await sbt.mint(to, ext, name, date);
  await tx.wait();

  console.log("Minted tokenId:", predicted.toString());
  console.log("tokenURI:", await sbt.tokenURI(predicted));
}

main().catch((e) => { console.error(e); process.exit(1); });
