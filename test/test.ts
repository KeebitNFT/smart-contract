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

const CONTRACT_NAME = "KeebitCollection";
const URI = "https://keebit.com/token/1";
const IDS = [1, 2, 3];
const FEE_PERCENT = 2;
const PRICE = ethers.utils.parseEther("10");

describe("Keebit processes", function () {
  before(async () => {
    const Factory = await ethers.getContractFactory("Factory");
    const Marketplace = await ethers.getContractFactory("Marketplace");

    factoryContract = await Factory.deploy();
    await factoryContract.deployed();

    marketplaceContract = await Marketplace.deploy(
      factoryContract.address,
      FEE_PERCENT
    );
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
    it("Should revert when non-owners call saveVendor()", async function () {
      await expect(
        factoryContract.connect(peer).saveVendor(peer.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should create a new NFT collection and mint NFTs", async function () {
      const result = await factoryContract
        .connect(vendor)
        .createNFT(CONTRACT_NAME, URI, IDS);
      //check token contract deployment
      tokenContract = await ethers.getContractAt(
        "Token",
        await factoryContract.tokens(0)
      );
      expect(await tokenContract.ids(0)).to.equal(IDS[0]);
      expect(await tokenContract.ids(2)).to.equal(IDS[2]);
      expect(await tokenContract.uri(0)).to.equal(URI);
      expect(await tokenContract.collectionName()).to.equal(CONTRACT_NAME);
      //check TokenDeployed event emitting
      expect(result).to.emit(factoryContract, "TokenDeployed");

      //check minting
      for (let i = 0; i < IDS.length; i++) {
        const tokenId = IDS[i];
        const balance = await tokenContract.balanceOf(vendor.address, tokenId);
        expect(balance).to.equal(1);
      }
    });
  });
  describe("Marketplace functions", function () {
    it("Should list NFTs", async function () {
      // frontend should call this function
      await tokenContract
        .connect(vendor)
        .setApprovalForAll(marketplaceContract.address, true);
      // smart contract begins from here
      const result = await marketplaceContract
        .connect(vendor)
        .listNFTs(tokenContract.address, [1, 2], 10);
      // check that NFTs are transferred to marketplace contract
      const itemCount = await marketplaceContract.itemCount();

      // check that NFTs are transferred to marketplace contract
      expect(
        await tokenContract.balanceOf(marketplaceContract.address, 1)
      ).to.be.equal(1);
      expect(
        await tokenContract.balanceOf(marketplaceContract.address, 2)
      ).to.equal(1);
      expect(await tokenContract.balanceOf(vendor.address, 1)).to.equal(0);
      expect(await tokenContract.balanceOf(vendor.address, 2)).to.equal(0);

      // check that itemId is the same itemCount
      expect((await marketplaceContract.nfts(itemCount)).itemId).to.equal(
        itemCount
      );
      // check that isOnlist = true
      expect((await marketplaceContract.nfts(itemCount)).isOnList).to.equal(
        true
      );
      // check that isOfficial = true
      expect((await marketplaceContract.nfts(itemCount)).isOfficial).to.equal(
        true
      );
      // check that event NFTListed is emitted
      expect(result).to.emit(marketplaceContract, "NFTListed");

      //check that only NFTs from factory can be listed
    });

    it("Should buy NFTs", async function () {
      // case 1: enough balance
      const totalPrice = PRICE.mul(100 + FEE_PERCENT).div(100);
      const msgValue = totalPrice;
      const sellerBalanceBefore = await vendor.getBalance();
      const buyerBalanceBefore = await peer.getBalance();

      const result = await marketplaceContract.connect(peer).buyNFT(1, {
        value: msgValue,
      });
      // check that ethers are transferred to seller
      const sellerBalanceAfter = await vendor.getBalance();
      const buyerBalanceAfter = await peer.getBalance();
      // expect(sellerBalanceAfter.minus(sellerBalanceBefore)).to.equal(msgValue);
    });
  });
});
