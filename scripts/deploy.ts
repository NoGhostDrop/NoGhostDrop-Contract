import { ethers } from "hardhat";

async function main() {
  const AirdropContract = await ethers.deployContract("Airdrop", [
    "0x3710a38d7310F0036a6094cC8b9aBae95Fcf2B20",
  ]);
  await AirdropContract.waitForDeployment();
  const AirdropAddress = await AirdropContract.getAddress();

  const TokenContract = await ethers.deployContract("ERC20", [
    "Human Token",
    "HUMN",
    ethers.parseEther("1000000"), // 100만개
  ]);
  await TokenContract.waitForDeployment();
  const TokenAddress = await TokenContract.getAddress();

  console.log("airdrop : ", AirdropAddress);
  console.log("token : ", TokenAddress);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
