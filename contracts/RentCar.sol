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
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//deployed to goerli at 0x4A7f21722Ec52B7f236fd452AD2dD1CDf0267e7e
//deployed 07.02.2023 22:45 to goerli at 0xbd6Bae596d644319f56EB0EbE7FC3BE75Fb87AbF
//deployed 09.02.2023 23:09 to goerli at 0xBBa0239E4DdFc990D630ce79dC17C9aCDA6558E8
//deployed 21.02.2023 23:09 to goerli at 0xCb858b19cef62Bd0506FcFE3C03AA24416362200
//deployed 08.03.2023 17:57 to mumbai at 0x2624a37a0eB19630F0C6576074CBd8a63989d13f
//deployed 21.02.2023 23:09 to goerli at 0x4bc02d27797eF895f5F6AF2461E2F3339e3CB09a
contract RentCar is ERC4907 { 
    address payable owner;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint32 platformFeeInPPM = 10000;
    uint SECONDS_IN_DAY = 5 * 60;// 24 * 60 * 60 ; 

    //The structure to store info about a listed car
    struct CarToRent{
        uint256 tokenId;
        address payable owner;
        uint256 pricePerDayInUsdCents;
        bool currentlyListed;
    }

    //The structure to store info about rent car request
    struct RentCarRequest{
        uint256 tokenId;
        address payable renter;
        uint256 daysForRent;
        uint256 totalPrice;
    }

    event CarAddedSuccess (
        uint256 indexed tokenId,
        address owner,
        uint256 pricePerDayInUsdCents,
        bool currentlyListed
    );
    
    event RentCarRequestCreatedSuccess (
        uint256 indexed tokenId,
        address renter,
        uint256 daysForRent,
        uint256 totalPrice
    );

    event RentCarRequestApproved (
        uint256 indexed tokenId,
        address renter
    );

    event RentCarRequestRejected (
        uint256 indexed tokenId,
        address renter
    );

    mapping(uint256 => CarToRent) private idToCarToRent;
    mapping(uint256 => RentCarRequest) private idToRentCarRequest;

    constructor(address ethToUsdPriceFeedAddress) ERC4907("Rentality Test", "RNTLTY") {
        owner = payable(msg.sender);

        //ETH/USD (Goerli Testnet) 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        //ETH/USD (Mumbai Testnet) 0x0715A7794a1dc8e42615F059dD6e406A6594651A
        ethToUsdPriceFeed = AggregatorV3Interface(ethToUsdPriceFeedAddress);
        currentEthToUsdPrice = getLatestEthToUsdPrice();
    }   
    
    function getOwner() public view returns (address) {    
        return owner;
    }

    function setPlatformFeeInPPM(uint32 valueInPPM) public {
        require(valueInPPM > 0, "Make sure the value isn't negative");
        require(valueInPPM < 1000000, "Value can't be more than 1000000");

        platformFeeInPPM = valueInPPM;
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

    function addCar(string memory tokenUri, uint256 pricePerDayInUsdCents) public returns (uint) {
        require(pricePerDayInUsdCents > 0, "Make sure the price isn't negative");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenUri);
        
        createCarToken(newTokenId, pricePerDayInUsdCents);

        return newTokenId;
    }

    function createCarToken(uint256 tokenId, uint256 pricePerDayInUsdCents) private {
        //Just sanity check
        require(pricePerDayInUsdCents > 0, "Make sure the price isn't negative");

        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        idToCarToRent[tokenId] = CarToRent(
            tokenId,
            payable(msg.sender),
            pricePerDayInUsdCents,
            true
        );

        _approve(address(this), tokenId);
        //_transfer(msg.sender, address(this), tokenId);
        
        emit CarAddedSuccess(
            tokenId,
            msg.sender,
            pricePerDayInUsdCents,
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

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

    function rentCar(uint256 tokenId, uint daysForRent) public payable {
        require(idToCarToRent[tokenId].owner != msg.sender, "Owner of the car cannot rent his own car");

        uint totalPriceInUsdCents = idToCarToRent[tokenId].pricePerDayInUsdCents * daysForRent;
        uint totalPriceInEth = getEthFromUsd(totalPriceInUsdCents);
        require(abs(int(msg.value)-int(totalPriceInEth)) < 0.0001 * (1 ether), "Please submit the asking price in order to complete the purchase");

        //update the details of the token
        //idToCarToRent[tokenId].currentlyListed = false;
        idToRentCarRequest[tokenId] = RentCarRequest(
            tokenId,
            payable(msg.sender),
            daysForRent,
            totalPriceInUsdCents
        );

        emit RentCarRequestCreatedSuccess(
            tokenId,
            msg.sender,
            daysForRent,
            totalPriceInUsdCents
        );        
    }

    function approveRentCar(uint256 tokenId) public {        
        require(idToCarToRent[tokenId].owner == msg.sender, "Only owner of the car can approve the request");

        uint256 rentPeriodInSeconds = idToRentCarRequest[tokenId].daysForRent * SECONDS_IN_DAY;
        uint64 expires = uint64(block.timestamp + rentPeriodInSeconds);

        setUser(tokenId, idToRentCarRequest[tokenId].renter, expires);
        
        uint totalPriceInEth = getEthFromUsd(idToRentCarRequest[tokenId].totalPrice);
        uint priceToSendToHost = totalPriceInEth * platformFeeInPPM / 1000000;
        require(idToCarToRent[tokenId].owner.send(priceToSendToHost));
        delete idToRentCarRequest[tokenId];        

        emit RentCarRequestApproved(
            tokenId,
            msg.sender
        );   
    }
    
    function rejectRentCar(uint256 tokenId) public {
        require(idToCarToRent[tokenId].owner == msg.sender, "Only owner of the car can reject the request");

        uint totalPriceInEth = getEthFromUsd(idToRentCarRequest[tokenId].totalPrice);
        require(idToRentCarRequest[tokenId].renter.send(totalPriceInEth));
        delete idToRentCarRequest[tokenId];

        emit RentCarRequestRejected(
            tokenId,
            msg.sender
        );   
    }

    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    
    // uint256 public interval;
    // uint256 public lastTimeStamp;
    AggregatorV3Interface internal ethToUsdPriceFeed;
    int256 private currentEthToUsdPrice; 

    // function getEthToUsdPrice() public returns (int256) {
    //     if ((block.timestamp - lastTimeStamp) > interval ) {
    //         lastTimeStamp = block.timestamp;         
    //         currentEthToUsdPrice =  getLatestEthToUsdPrice();
    //     } 
    // }

    function getLatestEthToUsdPrice() public view returns (int256) {
         (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ethToUsdPriceFeed.latestRoundData();

        return price; //  example price returned 165110000000
    }

    function getPriceFeedDecimals() public view returns (uint8) {
        return ethToUsdPriceFeed.decimals(); 
    }
    
    function getEthFromUsd(uint256 valueInUsdCents) public view returns (uint256) {
        return (valueInUsdCents * (1 ether) * (10 ** (getPriceFeedDecimals()-2))) / uint(getLatestEthToUsdPrice());
    }

    function getUsdFromEth(uint256 valueInEth) public view returns (uint256) {
        return (valueInEth * uint(getLatestEthToUsdPrice()) / ((10 ** (getPriceFeedDecimals()-2)) * (1 ether)));
    }

    // function safeMint(address to, string memory uri) public  onlyRole(MINTER_ROLE) {
    //     uint256 tokenId = _tokenIdCounter.current();
    //     _tokenIdCounter.increment();
    //     _safeMint(to, tokenId);
    //     _setTokenURI(tokenId, uri);
    // }
}
