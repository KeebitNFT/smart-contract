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

const COLLECTION_NAME = "KeebitCollection";
const URI = "https://keebit.com/token/1";

const SELLING_IDS = [1, 2, 3];
const UNLISTED_ID = 3;
const BUY_ID = 2;
const UPDATE_PRICE_ID = 1;
const REMAINING_IDS_AFTER_UNLISTED = [1, 2];

const PRICE = ethers.utils.parseEther("10");
const FEE_PERCENT = 2;
const PRICE_WITH_FEE = PRICE.mul(100 + FEE_PERCENT).div(100);
const UPDATED_PRICE = ethers.utils.parseEther("12");

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

  describe("Create NFT collection", async function () {
    it("Should save vendor address", async function () {
      await factoryContract.saveVendor(vendor.address);
      expect(await factoryContract.isVendor(vendor.address)).to.equal(true);
      expect(await factoryContract.isVendor(peer.address)).to.equal(false);
    });

    it("Should revert when non-owners call saveVendor()", async function () {
      await expect(
        factoryContract.connect(peer).saveVendor(peer.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should create a new NFT collection and mint NFTs", async function () {
      const result = await factoryContract
        .connect(vendor)
        .createNFT(COLLECTION_NAME, URI, SELLING_IDS);

      // Check token contract deployment
      tokenContract = await ethers.getContractAt(
        "Token",
        await factoryContract.tokens(0)
      );
      expect(await tokenContract.ids(0)).to.equal(SELLING_IDS[0]);
      expect(await tokenContract.ids(2)).to.equal(SELLING_IDS[2]);
      expect(await tokenContract.uri(0)).to.equal(URI);
      expect(await tokenContract.name()).to.equal(COLLECTION_NAME);
      expect(await tokenContract.vendorAddress()).to.equal(vendor.address);

      // Check TokenDeployed event emitting
      expect(result).to.emit(factoryContract, "TokenDeployed");

      // Check minting
      for (let i = 0; i < SELLING_IDS.length; i++) {
        const tokenId = SELLING_IDS[i];
        const balance = await tokenContract.balanceOf(vendor.address, tokenId);
        expect(balance).to.equal(1);
      }
    });
  });

  describe("Get all NFTs in my wallet", async function () {
    it("Should get all my NFTs in the token contracts contains in the factory contract", async function () {
      const nfts = await factoryContract.connect(vendor).getMyNFTs();

      const ids = [];
      for (const nft of nfts) {
        const [address, name, uri, tokenId] = nft;
        expect(address).to.equal(tokenContract.address);
        expect(name).to.equal(COLLECTION_NAME);
        expect(uri).to.equal(URI);
        ids.push(tokenId);
      }
      expect(SELLING_IDS).to.deep.equal(ids);
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
        .listNFTs(tokenContract.address, SELLING_IDS, PRICE);
      // check that NFTs are transferred to marketplace contract
      const itemCount = await marketplaceContract.itemCount();

      // check that NFTs are transferred to marketplace contract
      expect(
        await tokenContract.balanceOf(
          marketplaceContract.address,
          SELLING_IDS[0]
        )
      ).to.be.equal(1);
      expect(
        await tokenContract.balanceOf(
          marketplaceContract.address,
          SELLING_IDS[1]
        )
      ).to.equal(1);
      expect(
        await tokenContract.balanceOf(
          marketplaceContract.address,
          SELLING_IDS[2]
        )
      ).to.equal(1);

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
    });

    it("Should get all my NFTs selling in the marketplace", async function () {
      const listedNFTs = await marketplaceContract
        .connect(vendor)
        .getMyListedNFTs();

      const itemIds = [];
      const tokenIds = [];
      for (const nft of listedNFTs) {
        const [
          itemId,
          nftContract,
          name,
          uri,
          tokenId,
          price,
          vendorAddress,
          sellerAddress,
          ownerAddress,
          isOfficial,
          isOnList,
        ] = nft;
        itemIds.push(itemId);
        expect(nftContract).to.equal(tokenContract.address);
        expect(name).to.equal(COLLECTION_NAME);
        tokenIds.push(tokenId);
        expect(price).to.equal(PRICE_WITH_FEE);
        expect(vendorAddress).to.equal(vendor.address);
        expect(sellerAddress).to.equal(vendor.address);
        expect(ownerAddress).to.equal(marketplaceContract.address);
        expect(isOfficial).to.equal(true);
        expect(isOnList).to.equal(true);
      }
      expect(itemIds).to.deep.equal([1, 2, 3]);
      expect(tokenIds).to.deep.equal(SELLING_IDS);
    });

    it("Should unlist NFTs", async function () {
      const result = await marketplaceContract
        .connect(vendor)
        .unlistNFT(UNLISTED_ID);

      const listedNFTs = await marketplaceContract
        .connect(vendor)
        .getMyListedNFTs();

      expect(listedNFTs.length).to.equal(REMAINING_IDS_AFTER_UNLISTED.length);
      expect(result).to.emit(marketplaceContract, "NFTUnlisted");
    });

    it("Should buy NFTs by peer", async function () {
      // case 1: enough balance
      const msgValue = PRICE_WITH_FEE;
      const sellerBalanceBefore = await vendor.getBalance();
      const buyerBalanceBefore = await peer.getBalance();
      const ownerBalanceBefore = await owner.getBalance();
      const itemOnListBefore = await marketplaceContract.itemOnList();

      const result = await marketplaceContract.connect(peer).buyNFT(BUY_ID, {
        value: msgValue,
      });

      const sellerBalanceAfter = await vendor.getBalance();
      const buyerBalanceAfter = await peer.getBalance();
      const ownerBalanceAfter = await owner.getBalance();
      const itemOnListAfter = await marketplaceContract.itemOnList();

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
      expect(await tokenContract.balanceOf(peer.address, BUY_ID)).to.equal(1);
      expect(
        await tokenContract.balanceOf(marketplaceContract.address, BUY_ID)
      ).to.equal(0);

      //check that NFT is not on list anymore
      expect((await marketplaceContract.nfts(BUY_ID)).isOnList).to.equal(false);

      //check that the owner attribute of NFT is buyer
      expect((await marketplaceContract.nfts(BUY_ID)).owner).to.equal(
        peer.address
      );

      // check that # itemOnlist is decreased by 1
      expect(itemOnListBefore.sub(itemOnListAfter)).to.equal(1);

      // check that event NFTBought is emitted
      expect(result).to.emit(marketplaceContract, "NFTBought");
    });

    it("Should list NFTs by peer", async function () {
      // frontend should call this function
      await tokenContract
        .connect(peer)
        .setApprovalForAll(marketplaceContract.address, true);
      // smart contract begins from here
      const result = await marketplaceContract
        .connect(peer)
        .listNFTs(tokenContract.address, [BUY_ID], PRICE);
      // check that NFTs are transferred to marketplace contract
      const itemCount = await marketplaceContract.itemCount();

      // check that NFTs are transferred to marketplace contract
      expect(
        await tokenContract.balanceOf(marketplaceContract.address, BUY_ID)
      ).to.be.equal(1);

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
        false
      );
      // check that event NFTListed is emitted
      expect(result).to.emit(marketplaceContract, "NFTListed");
    });

    it("Should get all NFTs selling in the marketplace", async function () {
      const listedNFTs = await marketplaceContract.getListedNFTs();

      const itemIds = [];
      const tokenIds = [];
      const sellers = [];
      const isOfficials = [];
      for (const nft of listedNFTs) {
        const [
          itemId,
          nftContract,
          name,
          uri,
          tokenId,
          price,
          vendorAddress,
          sellerAddress,
          ownerAddress,
          isOfficial,
          isOnList,
        ] = nft;
        itemIds.push(itemId);
        expect(nftContract).to.equal(tokenContract.address);
        expect(name).to.equal(COLLECTION_NAME);
        tokenIds.push(tokenId);
        expect(uri).to.equal(URI);
        expect(price).to.equal(PRICE_WITH_FEE);
        sellers.push(sellerAddress);
        expect(vendorAddress).to.equal(vendor.address);
        expect(ownerAddress).to.equal(marketplaceContract.address);
        isOfficials.push(isOfficial);
        expect(isOnList).to.equal(true);
      }
      expect(itemIds).to.deep.equal([1, 4]);
      expect(tokenIds).to.deep.equal(REMAINING_IDS_AFTER_UNLISTED);
      expect(sellers).to.deep.equal([vendor.address, peer.address]);
      expect(isOfficials).to.deep.equal([true, false]);
    });

    it("Should update an NFT price", async function () {
      await marketplaceContract
        .connect(vendor)
        .updatePrice(UPDATE_PRICE_ID, UPDATED_PRICE);
    });

    it("Should return new price when calling getMyListedNFTs", async function () {
      const listedNFTs = await marketplaceContract
        .connect(vendor)
        .getMyListedNFTs();

      const nft = listedNFTs.find(
        (nft) => nft.itemId === ethers.BigNumber.from(UPDATE_PRICE_ID)
      );

      expect(nft).to.not.be.null;
      if (!nft) return;

      const [
        itemId,
        nftContract,
        name,
        uri,
        tokenId,
        price,
        vendorAddress,
        sellerAddress,
        ownerAddress,
        isOfficial,
        isOnList,
      ] = nft;

      expect(itemId).to.equal(UPDATE_PRICE_ID);
      expect(nftContract).to.equal(tokenContract.address);
      expect(name).to.equal(COLLECTION_NAME);
      expect(tokenId).to.equal(UPDATE_PRICE_ID);
      expect(uri).to.equal(URI);
      expect(price).to.equal(UPDATED_PRICE);
      expect(vendorAddress).to.equal(vendor.address);
      expect(sellerAddress).to.equal(vendor.address);
      expect(ownerAddress).to.equal(marketplaceContract.address);
      expect(isOfficial).to.equal(true);
      expect(isOnList).to.equal(true);
    });
  });
});
