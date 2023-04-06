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
const IDS_TO_LIST = [1, 2];
const FEE_PERCENT = 2;
const PRICE = ethers.utils.parseUnits("10", "ether");
const PRICE_WITH_FEE = PRICE.mul(100 + FEE_PERCENT).div(100);

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
        .listNFTs(tokenContract.address, IDS_TO_LIST, PRICE);
      // check that NFTs are transferred to marketplace contract
      const itemCount = await marketplaceContract.itemCount();

      // check that NFTs are transferred to marketplace contract
      expect(
        await tokenContract.balanceOf(
          marketplaceContract.address,
          IDS_TO_LIST[0]
        )
      ).to.be.equal(1);
      expect(
        await tokenContract.balanceOf(
          marketplaceContract.address,
          IDS_TO_LIST[1]
        )
      ).to.equal(1);
      expect(
        await tokenContract.balanceOf(vendor.address, IDS_TO_LIST[0])
      ).to.equal(0);
      expect(
        await tokenContract.balanceOf(vendor.address, IDS_TO_LIST[1])
      ).to.equal(0);

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
      const msgValue = PRICE_WITH_FEE;
      const sellerBalanceBefore = await vendor.getBalance();
      const buyerBalanceBefore = await peer.getBalance();
      const ownerBalanceBefore = await owner.getBalance();
      const itemOnListBefore = await marketplaceContract.itemOnList();
      const itemOnListAfter = await marketplaceContract.itemOnList();

      const result = await marketplaceContract
        .connect(peer)
        .buyNFT(IDS_TO_LIST[0], {
          value: msgValue,
        });

      const sellerBalanceAfter = await vendor.getBalance();
      const buyerBalanceAfter = await peer.getBalance();
      const ownerBalanceAfter = await owner.getBalance();

      // check that buyer get paid = NFT price
      expect(sellerBalanceAfter.sub(sellerBalanceBefore)).to.equal(PRICE);

      // check that marketplace owner get paid = fee
      expect(ownerBalanceAfter.sub(ownerBalanceBefore)).to.equal(
        PRICE_WITH_FEE.sub(PRICE)
      );

      // check that buyer paid = NFT price + fee
      expect(buyerBalanceBefore.sub(buyerBalanceAfter))
        .to.be.above(PRICE_WITH_FEE)
        .but.below(
          PRICE_WITH_FEE.add(ethers.utils.parseUnits("2100000", "gwei"))
        );

      // check that NFT is transferred from marketplace to buyer
      expect(
        await tokenContract.balanceOf(peer.address, IDS_TO_LIST[0])
      ).to.equal(1);
      expect(
        await tokenContract.balanceOf(
          marketplaceContract.address,
          IDS_TO_LIST[0]
        )
      ).to.equal(0);

      //check that NFT is not on list anymore
      expect((await marketplaceContract.nfts(1)).isOnList).to.equal(false);

      //check that the owner attribute of NFT is buyer
      expect((await marketplaceContract.nfts(1)).owner).to.equal(peer.address);

      // check that event NFTBought is emitted
      expect(result).to.emit(marketplaceContract, "NFTBought");
    });
  });
});
