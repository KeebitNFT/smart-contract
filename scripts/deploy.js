async function main() {
  const [deployer] = await ethers.getSigners();

  // deploy contracts
  const Marketplace = await ethers.getContractFactory("Marketplace");
  const marketplace = await Marketplace.deploy(5); // specify argument _feePercent
  await marketplace.deployed();

  console.log("Deployed contracts to", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
