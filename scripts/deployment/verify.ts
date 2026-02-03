import hre, { ethers } from "hardhat";

async function main() {
  const address = "0xa2FC5e13A7130413958e9434F21D92bCe527d27D";
  const chain = String(hre.network.name);
  if (chain !== "hardhat") {
    await hre.run("verify:verify", {
      address: address,
      constructorArguments: [],
    });
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});
