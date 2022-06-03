const hre = require("hardhat");

async function main() {
 
  const BREAD = await hre.ethers.getContractFactory("BreadToken");
	const bread = await BREAD.deploy(10000000);

	await bread.deployed();

	console.log("BearToken deployed to:", bread.address);

  const Contract = await hre.ethers.getContractFactory("MasterBaker");
  const contract = await Contract.deploy(bread.address, 10000, 1);

  await contract.deployed();

  console.log("Contract deployed to:", contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
