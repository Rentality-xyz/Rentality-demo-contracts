// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//Console functions to help debug the smart contract just like in Javascript
import "hardhat/console.sol";
//OpenZeppelin's NFT Standard Contracts. We will extend functions from this in our implementation
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC4907.sol";

//deployed to goerli at 0x4A7f21722Ec52B7f236fd452AD2dD1CDf0267e7e
//deployed 07.02.2023 22:45 to goerli at 0xbd6Bae596d644319f56EB0EbE7FC3BE75Fb87AbF
contract RentCar is ERC4907{

    using Counters for Counters.Counter;

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

    constructor() ERC4907("Rentality", "RNTLTY") {
        owner = payable(msg.sender);
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getCarToRentForId(uint256 tokenId) public view returns (CarToRent memory) {
        return idToCarToRent[tokenId];
    }

    function getLatestIdToCarToRent() public view returns (CarToRent memory) {
        return getCarToRentForId(getCurrentToken());
    }

    function addCar(string memory tokenUri, uint256 price) public payable returns (uint) {
        require(price > 0, "Make sure the price isn't negative");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenUri);
        
        createCarToken(newTokenId, price);

        return newTokenId;
    }

    function createCarToken(uint256 tokenId, uint256 price) private {
        //Just sanity check
        require(price > 0, "Make sure the price isn't negative");

        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        idToCarToRent[tokenId] = CarToRent(
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            true
        );

        _approve(address(this), tokenId);
        //_transfer(msg.sender, address(this), tokenId);
        
        emit TokenListedSuccess(
            tokenId,
            msg.sender,
            address(0),
            price,
            true
        );
    }
    
    //This will return all the NFTs currently listed to be sold on the marketplace
    function getAllCars() public view returns (CarToRent[] memory) {
        uint carCount = _tokenIdCounter.current();
        CarToRent[] memory tokens = new CarToRent[](carCount);
        
        for(uint i=0; i<carCount; i++)
        {
            tokens[i] =  idToCarToRent[i + 1];
        }

        return tokens;
    }

    function isCarAvailable(uint256 tokenId, address sender) private view returns (bool) {
        return idToCarToRent[tokenId].currentlyListed 
               && idToCarToRent[tokenId].owner != sender
               && userOf(tokenId) == address(0);
    }
    
    function getAllAvailableCars() public view returns (CarToRent[] memory) {
        uint totalItemCount = _tokenIdCounter.current();
        uint itemCount = 0;
        
        for(uint i=0; i < totalItemCount; i++)
        {
            uint currentId = i+1;
            if(isCarAvailable(currentId, msg.sender)){
                itemCount += 1;
            }
        }

        CarToRent[] memory result = new CarToRent[](itemCount);
        uint currentIndex = 0;

        for(uint i=0; i < totalItemCount; i++) {            
            uint currentId = i+1;
            if(isCarAvailable(currentId, msg.sender)){    
                CarToRent storage currentItem = idToCarToRent[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    function isMyCar(uint256 tokenId, address sender) private view returns (bool) {
        return idToCarToRent[tokenId].owner == sender;
    }

    function getMyCars() public view returns (CarToRent[] memory) {
        uint totalItemCount = _tokenIdCounter.current();
        uint itemCount = 0;
        
        for(uint i=0; i < totalItemCount; i++)
        {
            uint currentId = i+1;
            if(isMyCar(currentId, msg.sender)){
                itemCount += 1;
            }
        }

        CarToRent[] memory result = new CarToRent[](itemCount);
        uint currentIndex = 0;

        for(uint i=0; i < totalItemCount; i++) {            
            uint currentId = i+1;
            if(isMyCar(currentId, msg.sender)){    
                CarToRent storage currentItem = idToCarToRent[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    function isRentedByMe(uint256 tokenId, address sender) private view returns (bool) {
        return userOf(tokenId) == sender;
    }

    function getCarsRentedByMe() public view returns (CarToRent[] memory) {
        uint totalItemCount = _tokenIdCounter.current();
        uint itemCount = 0;
        
        for(uint i=0; i < totalItemCount; i++)
        {
            uint currentId = i+1;
            if(isRentedByMe(currentId, msg.sender)){
                itemCount += 1;
            }
        }

        CarToRent[] memory result = new CarToRent[](itemCount);
        uint currentIndex = 0;

        for(uint i=0; i < totalItemCount; i++) {            
            uint currentId = i+1;
            if(isRentedByMe(currentId, msg.sender)){    
                CarToRent storage currentItem = idToCarToRent[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }
    
    function convert (uint256 _a) public view returns (uint64) 
    {
        return uint64(_a);
    }

    function rentCar(uint256 tokenId, uint daysForRent) public payable {
        uint pricePerDay = idToCarToRent[tokenId].pricePerDay;
        uint price = pricePerDay * daysForRent;
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");

        //update the details of the token
        idToCarToRent[tokenId].currentlyListed = false;
        idToCarToRent[tokenId].renter = payable(msg.sender);

        uint64 expires = uint64(block.timestamp + daysForRent * (5 * 60));

        setUser(tokenId, msg.sender, expires);
        payable(idToCarToRent[tokenId].owner).transfer(msg.value);
    }

    function executeSale(uint256 tokenId) public payable {
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

    // function safeMint(address to, string memory uri) public  onlyRole(MINTER_ROLE) {
    //     uint256 tokenId = _tokenIdCounter.current();
    //     _tokenIdCounter.increment();
    //     _safeMint(to, tokenId);
    //     _setTokenURI(tokenId, uri);
    // }
}
