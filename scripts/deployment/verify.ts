import hre, { ethers } from "hardhat";

async function main() {
  const address = "0x4C687263C79Ca45915EBe6d79defeedc6569CDAf";
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
