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
    const Factory = await ethers.getContractFactory("Factory");
    const Marketplace = await ethers.getContractFactory("Marketplace");

    factoryContract = await Factory.deploy();
    await factoryContract.deployed();

    marketplaceContract = await Marketplace.deploy(factoryContract.address, 2);
    await marketplaceContract.deployed();

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
      tokenContract = await ethers.getContractAt(
        "Token",
        await factoryContract.tokens(0)
      );
      expect(await tokenContract.ids(0)).to.equal(ids[0]);
      expect(await tokenContract.ids(2)).to.equal(ids[2]);
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
  describe("List NFTs", function () {
    it("Should list NFTs", async function () {
      // frontend should call this function
      tokenContract
        .connect(vendor)
        .setApprovalForAll(marketplaceContract.address, true);
      // smart contract begins from here
      const result = await marketplaceContract
        .connect(vendor)
        .listNFTs(tokenContract.address, [1, 2], 10);
      // check that NFTs are transferred to marketplace contract
      expect(
        await tokenContract.balanceOf(marketplaceContract.address, 1)
      ).to.equal(1);
      expect(
        await tokenContract.balanceOf(marketplaceContract.address, 2)
      ).to.equal(1);
      // check that itemId is the same itemCount
      expect(
        (await marketplaceContract.nfts(tokenContract.address)).itemId
      ).to.equal(marketplaceContract.itemCount);
      // check that isOnlist = true
      expect(
        (await marketplaceContract.nfts(tokenContract.address)).isOnList
      ).to.equal(true);
      // check that isOfficial = true
      expect(
        (await marketplaceContract.nfts(tokenContract.address)).isOfficial
      ).to.equal(true);
      // check that event NFTListed is emitted
      expect(result).to.emit(marketplaceContract, "NFTListed");
    });
  });
});
