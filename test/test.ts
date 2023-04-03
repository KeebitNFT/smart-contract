import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("Keebit processes", function () {
  async function deployFactoryFixture() {
    const Marketplace = await ethers.getContractFactory("Marketplace");
    const Factory = await ethers.getContractFactory("Factory");

    const [owner, vendor, peer] = await ethers.getSigners();

    const marketplaceContract = await Marketplace.deploy(2);
    await marketplaceContract.deployed();

    const factoryContract = await Factory.deploy(marketplaceContract.address);
    await factoryContract.deployed();

    return { marketplaceContract, factoryContract, owner, vendor, peer };
  }
  describe("Save vendor", function () {
    it("Should save vendor address", async function () {
      const { factoryContract } = await loadFixture(deployFactoryFixture);
      factoryContract.saveVendor(vendor.address);
    });
  });
  describe("Create NFT collection", function () {
    const contractName = "KeebitCollection";
    const uri = "https://keebit.com/token/1";
    const ids = [1, 2, 3];
  });
});
