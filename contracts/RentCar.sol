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
//deployed 09.02.2023 23:09 to goerli at 0xBBa0239E4DdFc990D630ce79dC17C9aCDA6558E8
contract RentCar is ERC4907{
    using Counters for Counters.Counter;

    //_tokenIds variable has the most recent minted tokenId
    Counters.Counter private _tokenIdCounter;
    //owner is the contract address that created the smart contract
    address payable owner;

    uint dayInSeconds = 5 * 60;// 24 * 60 * 60 ; 

    //The structure to store info about a listed car
    struct CarToRent{
        uint256 tokenId;
        address payable owner;
        uint256 pricePerDay;
        bool currentlyListed;
    }

    struct RentCarRequest{
        uint256 tokenId;
        address payable renter;
        uint256 daysForRent;
        uint256 totalPrice;
    }

    //the event emitted when a token is successfully listed
    event TokenListedSuccess (
        uint256 indexed tokenId,
        address owner,
        uint256 pricePerDay,
        bool currentlyListed
    );

    //This mapping maps tokenId to token info and is helpful when retrieving details about a tokenId
    mapping(uint256 => CarToRent) private idToCarToRent;
    mapping(uint256 => RentCarRequest) private idToRentCarRequest;

    constructor() ERC4907("Rentality Test", "RNTLTY") {
        owner = payable(msg.sender);
    }

    function getCurrentToken() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getCarToRentForId(uint256 tokenId) public view returns (CarToRent memory) {
        return idToCarToRent[tokenId];
    }

    function getLatestCarToRent() public view returns (CarToRent memory) {
        return getCarToRentForId(getCurrentToken());
    }

    function getRentCarRequestForId(uint256 tokenId) public view returns (RentCarRequest memory) {
        return idToRentCarRequest[tokenId];
    }

    function getLatestRentCarRequest() public view returns (RentCarRequest memory) {
        return getRentCarRequestForId(getCurrentToken());
    }

    function addCar(string memory tokenUri, uint256 pricePerDay) public returns (uint) {
        require(pricePerDay > 0, "Make sure the price isn't negative");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenUri);
        
        createCarToken(newTokenId, pricePerDay);

        return newTokenId;
    }

    function createCarToken(uint256 tokenId, uint256 pricePerDay) private {
        //Just sanity check
        require(pricePerDay > 0, "Make sure the price isn't negative");

        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        idToCarToRent[tokenId] = CarToRent(
            tokenId,
            payable(msg.sender),
            pricePerDay,
            true
        );

        _approve(address(this), tokenId);
        //_transfer(msg.sender, address(this), tokenId);
        
        emit TokenListedSuccess(
            tokenId,
            msg.sender,
            pricePerDay,
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

    function existRequestForCar(uint256 tokenId, address sender) private view returns (bool) {
        return isMyCar(tokenId, sender) && idToRentCarRequest[tokenId].tokenId > 0;
    }

    function getRequestsForMyCars() public view returns (RentCarRequest[] memory) {
        uint totalItemCount = _tokenIdCounter.current();
        uint itemCount = 0;
        
        for(uint i=0; i < totalItemCount; i++)
        {
            uint currentId = i+1;
            if(existRequestForCar(currentId, msg.sender)){
                itemCount += 1;
            }
        }

        RentCarRequest[] memory result = new RentCarRequest[](itemCount);
        uint currentIndex = 0;

        for(uint i=0; i < totalItemCount; i++) {            
            uint currentId = i+1;
            if(existRequestForCar(currentId, msg.sender)){    
                RentCarRequest storage currentItem = idToRentCarRequest[currentId];
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

    function isMyRequest(uint256 tokenId, address sender) private view returns (bool) {
        return idToRentCarRequest[tokenId].tokenId > 0 && idToRentCarRequest[tokenId].renter == sender ;
    }

    function getMyRequests() public view returns (RentCarRequest[] memory) {
        uint totalItemCount = _tokenIdCounter.current();
        uint itemCount = 0;
        
        for(uint i=0; i < totalItemCount; i++)
        {
            uint currentId = i+1;
            if(isMyRequest(currentId, msg.sender)){
                itemCount += 1;
            }
        }

        RentCarRequest[] memory result = new RentCarRequest[](itemCount);
        uint currentIndex = 0;

        for(uint i=0; i < totalItemCount; i++) {            
            uint currentId = i+1;
            if(isMyRequest(currentId, msg.sender)){    
                RentCarRequest storage currentItem = idToRentCarRequest[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }
    
    function convert (uint256 _a) public pure returns (uint64) 
    {
        return uint64(_a);
    }

    function rentCar(uint256 tokenId, uint daysForRent) public payable {
        uint pricePerDay = idToCarToRent[tokenId].pricePerDay;
        uint totalPrice = pricePerDay * daysForRent;
        require(msg.value == totalPrice, "Please submit the asking price in order to complete the purchase");

        //update the details of the token
        //idToCarToRent[tokenId].currentlyListed = false;
        idToRentCarRequest[tokenId] = RentCarRequest(
            tokenId,
            payable(msg.sender),
            daysForRent,
            totalPrice
        );

    }

    function approveRentCar(uint256 tokenId) public {
        uint256 rentPeriodInSeconds = idToRentCarRequest[tokenId].daysForRent * dayInSeconds;
        uint64 expires = uint64(block.timestamp + rentPeriodInSeconds);

        setUser(tokenId, idToRentCarRequest[tokenId].renter, expires);
        
        require(idToCarToRent[tokenId].owner.send(idToRentCarRequest[tokenId].totalPrice));
        delete idToRentCarRequest[tokenId];
    }
    
    function rejectRentCar(uint256 tokenId) public {
        require(idToRentCarRequest[tokenId].renter.send(idToRentCarRequest[tokenId].totalPrice));
        delete idToRentCarRequest[tokenId];
    }

    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    // function safeMint(address to, string memory uri) public  onlyRole(MINTER_ROLE) {
    //     uint256 tokenId = _tokenIdCounter.current();
    //     _tokenIdCounter.increment();
    //     _safeMint(to, tokenId);
    //     _setTokenURI(tokenId, uri);
    // }
}
