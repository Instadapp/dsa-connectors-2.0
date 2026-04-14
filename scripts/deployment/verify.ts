import hre, { ethers } from "hardhat";

async function main() {
  const address = "0xD41ac7C73fe8A0a1D6F11fC43aE4E0661b8B5C87";
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
