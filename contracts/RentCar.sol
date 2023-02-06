// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//Console functions to help debug the smart contract just like in Javascript
import "hardhat/console.sol";
//OpenZeppelin's NFT Standard Contracts. We will extend functions from this in our implementation
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC4907.sol";

contract RentCar is ERC4907, AccessControl {

    using Counters for Counters.Counter;

    bytes32 public constant HOST_ROLE = keccak256("HOST_ROLE");
    bytes32 public constant GUEST_ROLE = keccak256("GUEST_ROLE");
    //_tokenIds variable has the most recent minted tokenId
    Counters.Counter private _tokenIdCounter;
    //owner is the contract address that created the smart contract
    address payable owner;

    //The structure to store info about a listed car
    struct CarToRent{
        uint256 tokenId;
        address payable owner;
        address payable renter;
        uint256 pricePerDay;
        bool currentlyListed;
    }

    //the event emitted when a token is successfully listed
    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint256 price,
        bool currentlyListed
    );

    //This mapping maps tokenId to token info and is helpful when retrieving details about a tokenId
    mapping(uint256 => CarToRent) private idToCarToRent;

    constructor() ERC4907("RentCar", "RNTC") {
        owner = payable(msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    function grantAdmin(address adminAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);
    }

    function grantHostRoleTo(address hostAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(HOST_ROLE, hostAddress);
    }

    function grantGuestRoleTo(address guestAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(GUEST_ROLE, guestAddress);
    }

    function getLatestIdToCarToRent() public view returns (CarToRent memory) {
        uint256 currentTokenId = _tokenIdCounter.current();
        return idToCarToRent[currentTokenId];
    }

    function getCarToRentForId(uint256 tokenId) public view returns (CarToRent memory) {
        return idToCarToRent[tokenId];
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    //The first time a token is created, it is listed here
    function createToken(string memory tokenUri, uint256 price) public payable  onlyRole(HOST_ROLE) returns (uint) {
        //Increment the tokenId counter, which is keeping track of the number of minted NFTs
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        //Mint the NFT with tokenId newTokenId to the address who called createToken
        _safeMint(msg.sender, newTokenId);

        //Map the tokenId to the tokenURI (which is an IPFS URL with the NFT metadata)
        _setTokenURI(newTokenId, tokenUri);

        //Helper function to update Global variables and emit an event
        createListedToken(newTokenId, price);

        return newTokenId;
    }

    function createListedToken(uint256 tokenId, uint256 price) private {
        //Just sanity check
        require(price > 0, "Make sure the price isn't negative");

        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        idToCarToRent[tokenId] = CarToRent(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            true
        );

        _transfer(msg.sender, address(this), tokenId);
        //Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit TokenListedSuccess(
            tokenId,
            address(this),
            msg.sender,
            price,
            true
        );
    }
    
    //This will return all the NFTs currently listed to be sold on the marketplace
    function getAllNFTs() public view onlyRole(HOST_ROLE) returns (CarToRent[] memory) {
        uint nftCount = _tokenIdCounter.current();
        CarToRent[] memory tokens = new CarToRent[](nftCount);
        uint currentIndex = 0;

        //at the moment currentlyListed is true for all, if it becomes false in the future we will 
        //filter out currentlyListed == false over here
        for(uint i=0;i<nftCount;i++)
        {
            uint currentId = i + 1;
            CarToRent storage currentItem = idToCarToRent[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
        }
        //the array 'tokens' has the list of all NFTs in the marketplace
        return tokens;
    }
    
    //Returns all the NFTs that the current user is owner or seller in
    function getMyNFTs() public view  onlyRole(HOST_ROLE) returns (CarToRent[] memory) {
        uint totalItemCount = _tokenIdCounter.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        
        //Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for(uint i=0; i < totalItemCount; i++)
        {
            if(idToCarToRent[i+1].owner == msg.sender || idToCarToRent[i+1].renter == msg.sender){
                itemCount += 1;
            }
        }

        //Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        CarToRent[] memory items = new CarToRent[](itemCount);
        for(uint i=0; i < totalItemCount; i++) {
            if(idToCarToRent[i+1].owner == msg.sender || idToCarToRent[i+1].renter == msg.sender) {
                uint currentId = i+1;
                CarToRent storage currentItem = idToCarToRent[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getRentedByMeNFTs() public view  onlyRole(GUEST_ROLE) returns (CarToRent[] memory) {
        uint totalItemCount = _tokenIdCounter.current();
        uint itemCount = 0;
        uint currentIndex = 0;
        
        //Important to get a count of all the NFTs that belong to the user before we can make an array for them
        for(uint i=0; i < totalItemCount; i++)
        {
            if (userOf(i) == msg.sender){
                itemCount += 1;
            }
        }

        //Once you have the count of relevant NFTs, create an array then store all the NFTs in it
        CarToRent[] memory items = new CarToRent[](itemCount);
        for(uint i=0; i < totalItemCount; i++) {
            if(userOf(i) == msg.sender) {
                uint currentId = i+1;
                CarToRent storage currentItem = idToCarToRent[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function executeSale(uint256 tokenId) public payable onlyRole(GUEST_ROLE) {
        uint price = idToCarToRent[tokenId].pricePerDay;
        address renter = idToCarToRent[tokenId].renter;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        //update the details of the token
        idToCarToRent[tokenId].currentlyListed = true;
        idToCarToRent[tokenId].renter = payable(msg.sender);

        //Actually transfer the token to the new owner
        _transfer(address(this), msg.sender, tokenId);
        //approve the marketplace to sell NFTs on your behalf
        approve(address(this), tokenId);

        //Transfer the proceeds from the sale to the seller of the NFT
        payable(renter).transfer(msg.value);
    }    
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC4907, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // function safeMint(address to, string memory uri) public  onlyRole(MINTER_ROLE) {
    //     uint256 tokenId = _tokenIdCounter.current();
    //     _tokenIdCounter.increment();
    //     _safeMint(to, tokenId);
    //     _setTokenURI(tokenId, uri);
    // }
}
