// import { expect } from "chai";
// import { ethers } from "hardhat";
// import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
// const uri = "https://keebit.com/token/1";

// describe("Token contract", function () {
//   async function deployTokenFixture() {
//     const Token = await ethers.getContractFactory("Token");
//     const Marketplace = await ethers.getContractFactory("Marketplace");

//     const [owner, addr1] = await ethers.getSigners();

//     const tokenContract = await Token.deploy(
//       "KeebitCollection",
//       uri,
//       [1, 2, 3]
//     );
//     await tokenContract.deployed();

//     const marketplaceContract = await Marketplace.deploy(2);
//     await marketplaceContract.deployed();

//     return { marketplaceContract, tokenContract, owner, addr1 };
//   }

//   describe("Deployment", function () {
//     it("Should set uri when deployed by the contract owner", async function () {
//       const { tokenContract, owner } = await loadFixture(deployTokenFixture);
//       // call get uri function from erc1155
//       expect((await tokenContract.baseMetadataURI()).toString()).to.equal(uri);
//     });

//     // it("Should revert when called by non-owners", async function () {
//     //   const { tokenContract, owner, addr1 } = await loadFixture(
//     //     deployTokenFixture
//     //   );
//     //   const uri = "https://keebit.com/token/1";
//     //   expect(
//     //     await tokenContract.connect(addr1).setURI(uri)
//     //   ).to.be.revertedWith("Ownable: caller is not the owner");
//     // });
//   });

//   describe("setMintFee", function () {
//     it("Should set mint fee when called by the contract owner", async function () {
//       const { tokenContract, owner } = await loadFixture(deployTokenFixture);
//       const fee = 5;
//       await tokenContract.connect(owner).setMintFee(fee);
//       expect(await tokenContract.mintFee()).to.equal(fee);
//     });

//     // it("Should revert when called by non-owners", async function () {
//     //   const { tokenContract, owner, addr1 } = await loadFixture(
//     //     deployTokenFixture
//     //   );
//     //   const fee = 5;
//     //   expect(await tokenContract.connect(addr1).setMintFee(fee)).fail(
//     //     "Ownable: caller is not the owner"
//     //   );
//     // });
//   });

//   describe("mintBatch", function () {
//     it("Should mint a specified amount of tokens to an account", async function () {
//       const { marketplaceContract, tokenContract, addr1 } = await loadFixture(
//         deployTokenFixture
//       );
//       const ids = [1, 2, 3, 4, 5];
//       const realAddr1 = addr1.address;
//       // const addresses = [realAddr1, realAddr1, realAddr1, realAddr1, realAddr1];
//       //   const initialBalance = await tokenContract.balanceOfBatch(addresses, ids);
//       await tokenContract.mintBatch(
//         realAddr1,
//         ids,
//         marketplaceContract.address
//       );
//       //   const finalBalance = await tokenContract.balanceOfBatch(addresses, ids);
//       // Check the final balance of addr1
//       //   expect(finalBalance.sub(initialBalance)).to.equal(ids.length);

//       // Check the token balance of each tokenId
//       for (let i = 0; i < ids.length; i++) {
//         const tokenId = ids[i];
//         const balance = await tokenContract.balanceOf(realAddr1, tokenId);
//         expect(balance).to.equal(1);
//       }

//       //check the returned ids
//     });
//   });
// });
