import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("Factory contract", function () {
  async function deployFactoryFixture() {
    const Marketplace = await ethers.getContractFactory("Marketplace");
    const Factory = await ethers.getContractFactory("Factory");

    const [owner, addr1] = await ethers.getSigners();

    const marketplaceContract = await Marketplace.deploy(2);
    await marketplaceContract.deployed();

    const factoryContract = await Factory.deploy(marketplaceContract.address);
    await factoryContract.deployed();

    return { marketplaceContract, factoryContract, owner, addr1 };
  }

  describe("createAndList", function () {
    const contractName = "KeebitCollection";
    const uri = "https://keebit.com/token/1";
    const ids = [1, 2, 3];
    const price = 20;
    it("Should create a new token collection contract and list all NFTs in that collection", async function () {
      const { factoryContract, owner, addr1 } = await loadFixture(
        deployFactoryFixture
      );
      const result = await factoryContract
        .connect(addr1)
        .createAndList(contractName, uri, ids, price);

      //check token contract deployment
      const tokenContract = await ethers.getContractAt(
        "Token",
        await factoryContract.tokens(0)
      );
      expect(await tokenContract.ids(0)).to.equal(ids[0]);
      expect(await tokenContract.ids(2)).to.equal(ids[2]);
      expect(await tokenContract.baseMetadataURI()).to.equal(uri);
      expect(await tokenContract.collectionName()).to.equal(contractName);

      //check TokenDeployed event emitting
      expect(result).to.emit(factoryContract, "TokenDeployed");

      //check minting
      for (let i = 0; i < ids.length; i++) {
        const tokenId = ids[i];
        const balance = await tokenContract.balanceOf(
          tokenContract.owner(),
          tokenId
        );
        expect(balance).to.equal(1);
      }
      //check TokenMinted event emitting
      expect(result).to.emit(factoryContract, "TokenMinted");

      //check listing
    });
  });
});
