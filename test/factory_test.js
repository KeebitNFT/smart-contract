const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const uri = "https://keebit.com/token/1";

describe("Token contract", function () {
  async function deployFactoryFixture() {
    const Factory = await ethers.getContractFactory("Factory");
    const [owner, addr1] = await ethers.getSigners();
    const factoryContract = await Token.deploy(
      "KeebitCollection",
      uri,
      [1, 2, 3]
    );
    await factoryContract.deployed();
    return { factoryContract, owner, addr1 };
  }
});
