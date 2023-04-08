import { ethers } from 'hardhat';

async function main() {
  // deploy contracts
  const Factory = await ethers.getContractFactory('Factory');
  const factory = await Factory.deploy();
  await factory.deployed();

  const Marketplace = await ethers.getContractFactory('Marketplace');
  const marketplace = await Marketplace.deploy(factory.address, 5);
  await marketplace.deployed();

  console.log('Factory address:', factory.address);
  console.log('Marketplace address:', marketplace.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
