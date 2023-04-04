import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Factory } from "../typechain-types/";
import { Marketplace } from "../typechain-types/";
import { Token } from "../typechain-types/";

let marketplaceContract: Marketplace;
let factoryContract: Factory;
let tokenContract: Token;
let owner: SignerWithAddress;
let vendor: SignerWithAddress;
let peer: SignerWithAddress;

describe("Keebit processes", function () {
  before(async () => {
    const Marketplace = await ethers.getContractFactory("Marketplace");
    const Factory = await ethers.getContractFactory("Factory");

    marketplaceContract = await Marketplace.deploy(2);
    await marketplaceContract.deployed();

    factoryContract = await Factory.deploy();
    await factoryContract.deployed();

    [owner, vendor, peer] = await ethers.getSigners();
  });

  describe("To create NFT collection", async function () {
    it("Should save vendor address", async function () {
      await factoryContract.saveVendor(vendor.address);
      expect(await factoryContract.isVendor(vendor.address)).to.equal(true);
      expect(await factoryContract.isVendor(peer.address)).to.equal(false);

      // check that only owner can call this function
    });

    it("Should create a new NFT collection and mint NFTs", async function () {
      const contractName = "KeebitCollection";
      const uri = "https://keebit.com/token/1";
      const ids = [1, 2, 3];

      const result = await factoryContract
        .connect(vendor)
        .createNFT(contractName, uri, ids);
      //check token contract deployment
      const tokenContract = await ethers.getContractAt(
        "Token",
        await factoryContract.tokens(0)
      );
      //   expect(await tokenContract.ids(0)).to.equal(ids[0]);
      //   expect(await tokenContract.ids(2)).to.equal(ids[2]);
      expect(await tokenContract.uri(0)).to.equal(uri);
      expect(await tokenContract.collectionName()).to.equal(contractName);
      //check TokenDeployed event emitting
      expect(result).to.emit(factoryContract, "TokenDeployed");

      //check minting
      for (let i = 0; i < ids.length; i++) {
        const tokenId = ids[i];
        const balance = await tokenContract.balanceOf(vendor.address, tokenId);
        expect(balance).to.equal(1);
      }
    });
  });
  //   describe("Create a collection and mint NFTs to caller", function () {});
});
