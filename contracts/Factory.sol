// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Token.sol";
import "hardhat/console.sol";

contract Factory is Ownable {
    Token[] public tokens;
    mapping(address => bool) public isToken;
    mapping(address => bool) public isVendor;

    struct factoryNFT {
        address tokenAddress;
        string collectionName;
        string uri;
        uint tokenId;
    }

    event TokenDeployed(address owner, address tokenContract); //emitted when ERC1155 token is deployed
    event TokenMinted(address owner, address tokenContract, uint amount); //emmited when ERC1155 token is minted

    function saveVendor(address _vendor) external onlyOwner {
        isVendor[_vendor] = true;
    }

    function createNFT(
        string memory _contractName,
        string memory _uri,
        uint[] memory _ids
    ) external returns (address) {
        require(
            isVendor[msg.sender] == true,
            "Only a valid vendor can create NFT"
        );
        // deploy contract
        Token tokenContract = new Token(_contractName, _uri, _ids);
        tokens.push(tokenContract);
        isToken[address(tokenContract)] = true;
        emit TokenDeployed(msg.sender, address(tokenContract));

        //mint NFT
        _mintNFT(tokenContract, _ids);

        return (address(tokenContract));
    }

    function _mintNFT(Token _token, uint[] memory _ids) private {
        _token.mintBatch(msg.sender, _ids);
        emit TokenMinted(msg.sender, address(_token), _ids.length);
    }

    function getMyNFT() external view returns (factoryNFT[] memory) {
        factoryNFT[] memory myNFTArray;
        uint counter;
        for (uint i = 0; i < tokens.length; i++) {
            // create array of accounts and ids
            uint num = tokens[i].countNFT();
            address[] memory owners = new address[](num);
            uint[] memory ids = new uint[](num);
            for (uint j = 0; j < num; j++) {
                owners[j] = msg.sender;
                ids[j] = j + 1; // id starts from 1
            }
            // get balance of all ids
            uint[] memory balance = tokens[i].balanceOfBatch(owners, ids);

            for (uint k = 0; k < balance.length; k++) {
                if (balance[k] > 0) {
                    myNFTArray[counter] = factoryNFT(
                        address(tokens[i]),
                        tokens[i].collectionName(),
                        tokens[i].uri(1),
                        k + 1
                    );
                    counter++;
                }
            }
        }
        return (myNFTArray);
    }
}
