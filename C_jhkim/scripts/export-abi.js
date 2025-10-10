const fs = require("fs");
const path = require("path");

const artifact = path.join(__dirname, "..", "artifacts", "contracts", "FrozenClockSBT.sol", "FrozenClockSBT.json");
const outDir = path.join(__dirname, "..", "web", "abi");

if (!fs.existsSync(artifact)) {
  console.error("Artifact not found. Run `npx hardhat compile` first.");
  process.exit(1);
}
const { abi } = JSON.parse(fs.readFileSync(artifact, "utf8"));
fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, "FrozenClockSBT.json"), JSON.stringify(abi, null, 2));
console.log("ABI exported to web/abi/FrozenClockSBT.json");
