import { ethers } from "hardhat";

async function main() {
  const Contract = await ethers.getContractFactory("Token");
  const name = "MyContract";
  const contract = await Contract.deploy(name);

  await contract.deployed();

  console.log("contract address is :", contract.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
