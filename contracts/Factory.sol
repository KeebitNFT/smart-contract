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

    struct FactoryNFT {
        address nftContract;
        string collectionName;
        string uri;
        uint tokenId;
        address vendor;
    }

    event TokenDeployed(address indexed owner, address indexed tokenContract); //emitted when ERC1155 token is deployed
    event TokenMinted(
        address indexed owner,
        address indexed tokenContract,
        uint amount
    ); //emmited when ERC1155 token is minted

    function saveVendor(address _vendor) external onlyOwner {
        isVendor[_vendor] = true;
    }

    function createNFT(
        string memory _collectionName,
        string memory _uri,
        uint[] memory _ids
    ) external returns (address) {
        require(
            isVendor[msg.sender] == true,
            "Only a valid vendor can create NFT"
        );

        // Deploy contract
        Token tokenContract = new Token(
            _collectionName,
            _uri,
            _ids,
            msg.sender
        );
        tokens.push(tokenContract);
        isToken[address(tokenContract)] = true;
        emit TokenDeployed(msg.sender, address(tokenContract));

        // Mint NFT
        _mintNFT(tokenContract, _ids);

        return (address(tokenContract));
    }

    function _mintNFT(Token _token, uint[] memory _ids) private {
        _token.mintBatch(msg.sender, _ids);
        emit TokenMinted(msg.sender, address(_token), _ids.length);
    }

    function countMyNFTs() public view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < tokens.length; i++) {
            // Create array of accounts and ids
            uint num = tokens[i].countNFT();
            address[] memory owners = new address[](num);
            uint[] memory ids = new uint[](num);
            for (uint j = 0; j < num; j++) {
                owners[j] = msg.sender;
                ids[j] = j + 1; // id starts from 1
            }

            // Get owner's balance of all ids
            uint[] memory balances = tokens[i].balanceOfBatch(owners, ids);

            // Get owner's NFTs
            for (uint k = 0; k < balances.length; k++) {
                if (balances[k] > 0) {
                    count++;
                }
            }
        }
        return (count);
    }

    function getMyNFTs() external view returns (FactoryNFT[] memory) {
        uint nftsCount = countMyNFTs();
        FactoryNFT[] memory myNFTs = new FactoryNFT[](nftsCount);
        uint counter;
        for (uint i = 0; i < tokens.length; i++) {
            // Create array of accounts and ids
            uint num = tokens[i].countNFT();
            address[] memory owners = new address[](num);
            uint[] memory ids = new uint[](num);
            for (uint j = 0; j < num; j++) {
                owners[j] = msg.sender;
                ids[j] = j + 1; // id starts from 1
            }

            // Get owner's balance of all ids
            uint[] memory balances = tokens[i].balanceOfBatch(owners, ids);

            // Get owner's NFTs
            for (uint k = 0; k < balances.length; k++) {
                if (balances[k] > 0) {
                    myNFTs[counter] = (
                        FactoryNFT(
                            address(tokens[i]),
                            tokens[i].name(),
                            tokens[i].uri(1),
                            k + 1,
                            tokens[i].vendorAddress()
                        )
                    );
                    counter++;
                }
            }
        }
        return (myNFTs);
    }
}
