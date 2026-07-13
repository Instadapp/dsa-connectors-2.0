import hre, { ethers } from "hardhat";

async function main() {
  const address = "0x13b2bC24371923FAC3b86aE6576ad2223319C8F3";
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
