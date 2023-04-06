import { expect } from 'chai';
import { ethers } from 'hardhat';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { Factory } from '../typechain-types/';
import { Marketplace } from '../typechain-types/';
import { Token } from '../typechain-types/';

let marketplaceContract: Marketplace;
let factoryContract: Factory;
let tokenContract: Token;
let owner: SignerWithAddress;
let vendor: SignerWithAddress;
let peer: SignerWithAddress;

const COLLECTION_NAME = 'KeebitCollection';
const URI = 'https://keebit.com/token/1';

const SELLING_IDS = [1, 2, 3];
const UNLISTED_ID = 3;
const BUY_ID = 2;
const UPDATE_PRICE_ID = 1;
const REMAINING_IDS_AFTER_UNLISTED = [1, 2];
const REMAINING_IDS_AFTER_BUY = [1];

const PRICE = ethers.utils.parseEther('10'); // MATIC
const UPDATED_PRICE = ethers.utils.parseEther('12'); // MATIC

describe('Keebit processes', function () {
  before(async () => {
    const Factory = await ethers.getContractFactory('Factory');
    const Marketplace = await ethers.getContractFactory('Marketplace');

    factoryContract = await Factory.deploy();
    await factoryContract.deployed();

    marketplaceContract = await Marketplace.deploy(factoryContract.address, 2);
    await marketplaceContract.deployed();

    [owner, vendor, peer] = await ethers.getSigners();
  });

  describe('Create NFT collection', async function () {
    it('Should save vendor address', async function () {
      await factoryContract.saveVendor(vendor.address);
      expect(await factoryContract.isVendor(vendor.address)).to.equal(true);
      expect(await factoryContract.isVendor(peer.address)).to.equal(false);
    });

    it('Should create a new NFT collection and mint NFTs', async function () {
      const result = await factoryContract
        .connect(vendor)
        .createNFT(COLLECTION_NAME, URI, SELLING_IDS);

      // Check token contract deployment
      tokenContract = await ethers.getContractAt(
        'Token',
        await factoryContract.tokens(0)
      );
      expect(await tokenContract.ids(0)).to.equal(SELLING_IDS[0]);
      expect(await tokenContract.ids(2)).to.equal(SELLING_IDS[2]);
      expect(await tokenContract.uri(0)).to.equal(URI);
      expect(await tokenContract.collectionName()).to.equal(COLLECTION_NAME);

      // Check TokenDeployed event emitting
      expect(result).to.emit(factoryContract, 'TokenDeployed');

      // Check minting
      for (let i = 0; i < SELLING_IDS.length; i++) {
        const tokenId = SELLING_IDS[i];
        const balance = await tokenContract.balanceOf(vendor.address, tokenId);
        expect(balance).to.equal(1);
      }
    });
  });

  describe('Get all NFTs in my wallet', async function () {
    it('Should get all my NFTs in the token contracts contains in the factory contract', async function () {
      const nfts = await factoryContract.connect(vendor).getMyNFTs();

      const ids = [];
      for (const nft of nfts) {
        const [address, collectionName, uri, tokenId] = nft;
        expect(address).to.equal(tokenContract.address);
        expect(collectionName).to.equal(COLLECTION_NAME);
        expect(uri).to.equal(URI);
        ids.push(tokenId);
      }
      expect(SELLING_IDS).to.deep.equal(ids);
    });
  });

  describe('List NFTs', function () {
    it('Should list NFTs', async function () {
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

      expect(
        await tokenContract.balanceOf(marketplaceContract.address, 1)
      ).to.be.equal(1);
      expect(
        await tokenContract.balanceOf(marketplaceContract.address, 2)
      ).to.equal(1);
      expect(
        await tokenContract.balanceOf(marketplaceContract.address, 3)
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
      expect(result).to.emit(marketplaceContract, 'NFTListed');
    });
  });

  describe('Get my listing NFTs', function () {
    it('Should get all my NFTs selling in the marketplace', async function () {
      const listedNFTs = await marketplaceContract
        .connect(vendor)
        .getMyListedNFTs();

      const itemIds = [];
      const tokenIds = [];
      for (const nft of listedNFTs) {
        const [
          itemId,
          nftContract,
          collectionName,
          tokenId,
          price,
          seller,
          owner,
          isOfficial,
          isOnList,
        ] = nft;
        itemIds.push(itemId);
        expect(nftContract).to.equal(tokenContract.address);
        expect(collectionName).to.equal(COLLECTION_NAME);
        tokenIds.push(tokenId);
        expect(price).to.equal(PRICE);
        expect(seller).to.equal(vendor.address);
        expect(owner).to.equal(marketplaceContract.address);
        expect(isOfficial).to.equal(true);
        expect(isOnList).to.equal(true);
      }
      expect(itemIds).to.deep.equal(SELLING_IDS);
      expect(tokenIds).to.deep.equal(SELLING_IDS);
    });
  });

  describe('Unlist NFTs', function () {
    it('Should unlist NFTs', async function () {
      await marketplaceContract.connect(vendor).unlistNFT(UNLISTED_ID);

      const listedNFTs = await marketplaceContract
        .connect(vendor)
        .getMyListedNFTs();

      expect(listedNFTs.length).to.equal(REMAINING_IDS_AFTER_UNLISTED.length);
    });
  });

  // PEER buy 1 NFT
  // PEER list 1 NFT

  describe('Get listing NFTs', function () {
    it('Should get all NFTs selling in the marketplace', async function () {
      const listedNFTs = await marketplaceContract.getListedNFTs();

      const itemIds = [];
      const tokenIds = [];
      for (const nft of listedNFTs) {
        const [
          itemId,
          nftContract,
          collectionName,
          tokenId,
          price,
          seller,
          owner,
          isOfficial,
          isOnList,
        ] = nft;
        itemIds.push(itemId);
        expect(nftContract).to.equal(tokenContract.address);
        expect(collectionName).to.equal(COLLECTION_NAME);
        tokenIds.push(tokenId);
        expect(price).to.equal(PRICE);
        expect(seller).to.equal(vendor.address);
        expect(owner).to.equal(marketplaceContract.address);
        expect(isOfficial).to.equal(true);
        expect(isOnList).to.equal(true);
      }
      expect(itemIds).to.deep.equal(REMAINING_IDS_AFTER_UNLISTED);
      expect(tokenIds).to.deep.equal(REMAINING_IDS_AFTER_UNLISTED);
    });
  });

  describe('Update price', function () {
    it('Should update an NFT price', async function () {
      await marketplaceContract
        .connect(vendor)
        .updatePrice(UPDATE_PRICE_ID, UPDATED_PRICE);
    });

    it('Should return new price when calling getMyListedNFTs', async function () {
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
        collectionName,
        tokenId,
        price,
        seller,
        owner,
        isOfficial,
        isOnList,
      ] = nft;

      expect(itemId).to.equal(UPDATE_PRICE_ID);
      expect(nftContract).to.equal(tokenContract.address);
      expect(collectionName).to.equal(COLLECTION_NAME);
      expect(tokenId).to.equal(UPDATE_PRICE_ID);
      expect(price).to.equal(UPDATED_PRICE);
      expect(seller).to.equal(vendor.address);
      expect(owner).to.equal(marketplaceContract.address);
      expect(isOfficial).to.equal(true);
      expect(isOnList).to.equal(true);
    });
  });
});
