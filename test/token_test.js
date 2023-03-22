const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Token contract", function () {
  async function deployTokenFixture() {
    const Token = await ethers.getContractFactory("Token");
    const [owner, address1] = await ethers.getSigners();
    const tokenContract = await Token.deploy();
    await tokenContract.deployed();
    return { tokenContract, owner, address1 };
  }

  describe("setURI", function () {
    it("Should set uri when called by the contract owner", async function () {
      const { tokenContract, owner } = await loadFixture(deployTokenFixture);
      const uri = "https://keebit.com/token/1";
      await tokenContract.connect(owner).setURI(uri);
      expect(tokenContract.baseMetadataURI).to.equal(uri);
    });

    it("Should revert when called by non-owners", async function () {
      const { tokenContract, owner, address1 } = await loadFixture(
        deployTokenFixture
      );
      const uri = "https://keebit.com/token/1";
      expect(
        await tokenContract.connect(address1).setURI(uri)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("setMintFee", function () {
    it("Should set mint fee when called by the contract owner", async function () {
      const { tokenContract, owner } = await loadFixture(deployTokenFixture);
      const fee = 5;
      await tokenContract.connect(owner).setMintFee(fee);
      expect(tokenContract.mintFee).to.equal(fee);
    });

    it("Should revert when called by non-owners", async function () {
      const { tokenContract, owner, address1 } = await loadFixture(
        deployTokenFixture
      );
      const fee = 5;
      expect(
        await tokenContract.connect(address1).setMintFee(fee)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("mintBatch", function () {
    it("Should mint a specified amount of tokens to an account", async function () {
      const { tokenContract, address1 } = await loadFixture(deployTokenFixture);
      const ids = [1, 2, 3, 4, 5];
      const initialBalance = await token.balanceOf(address1);
      await tokenContract.mintBatch(address1, ids);
      const finalBalance = await token.balanceOf(address1);
      // Check the final balance of address1
      expect(finalBalance.sub(initialBalance)).to.equal(ids.length);

      // Check the token balance of each tokenId
      for (let i = 0; i < ids.length; i++) {
        const tokenId = ids[i];
        const balance = await tokenContract.balanceOf(address1, tokenId);
        expect(balance).to.equal(1);
      }

      //check the returned ids
    });
  });
});
