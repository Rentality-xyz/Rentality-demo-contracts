// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//Console functions to help debug the smart contract just like in Javascript
import "hardhat/console.sol";
//OpenZeppelin's NFT Standard Contracts. We will extend functions from this in our implementation
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC4907.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//deployed to goerli at 0x4A7f21722Ec52B7f236fd452AD2dD1CDf0267e7e
//deployed 07.02.2023 22:45 to goerli at 0xbd6Bae596d644319f56EB0EbE7FC3BE75Fb87AbF
//deployed 09.02.2023 23:09 to goerli at 0xBBa0239E4DdFc990D630ce79dC17C9aCDA6558E8
//deployed 21.02.2023 23:09 to goerli at 0xCb858b19cef62Bd0506FcFE3C03AA24416362200
//deployed 08.03.2023 17:57 to mumbai at 0x2624a37a0eB19630F0C6576074CBd8a63989d13f
//deployed 08.03.2023 17:58 to goerli at 0x4bc02d27797eF895f5F6AF2461E2F3339e3CB09a
//deployed 08.03.2023 19:43 to goerli at 0x9C1Bb3a3B82bBD64beD283dAd9c91fC1b34c9920
//deployed 08.03.2023 21:53 to goerli at 0xB4FDc13b6991671533FCb814037abFA77612D6c8
contract RentCar is ERC4907, Ownable { 
    using Counters for Counters.Counter;
    Counters.Counter private _carIdCounter;

    //TODO enum CarStatus { AVAILABLE, RENTED }
    //The structure to store info about a listed car
    struct CarToRent{
        uint256 carId;
        address payable owner;
        uint256 pricePerDayInUsdCents;
        bool currentlyListed;
    }

    //The structure to store info about rent car request
    struct RentCarRequest{
        uint256 carId;
        address payable renter;
        uint256 daysForRent;
        uint256 totalPrice;
        uint256 startDateTime;
        uint256 endDateTime;
        string startLocation;
        string endLocation;        
        bool approved;
    }

    event CarAddedSuccess (
        uint256 indexed carId,
        address owner,
        uint256 pricePerDayInUsdCents,
        bool currentlyListed
    );
    
    event RentCarRequestCreatedSuccess (
        uint256 indexed carId,
        address renter,
        uint256 daysForRent,
        uint256 totalPrice
    );

    event RentCarRequestApproved (
        uint256 indexed carId,
        address renter
    );

    event RentCarRequestRejected (
        uint256 indexed carId,
        address renter
    );

    uint32 platformFeeInPPM = 10000;
    uint SECONDS_IN_DAY = 5 * 60;// 24 * 60 * 60 ; 
    mapping(uint256 => CarToRent) private idToCarToRent;
    mapping(uint256 => RentCarRequest) private idToRentCarRequest;

    constructor(address ethToUsdPriceFeedAddress) ERC4907("Rentality Test", "RNTLTY") {
        //ETH/USD (Goerli Testnet) 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        //ETH/USD (Mumbai Testnet) 0x0715A7794a1dc8e42615F059dD6e406A6594651A
        //ETH/USD (Sepolia Testnet) 0x694AA1769357215DE4FAC081bf1f309aDC325306
        ethToUsdPriceFeed = AggregatorV3Interface(ethToUsdPriceFeedAddress);
        currentEthToUsdPrice = getLatestEthToUsdPrice();
    }   

    function setPlatformFeeInPPM(uint32 valueInPPM) public onlyOwner {
        require(valueInPPM > 0, "Make sure the value isn't negative");
        require(valueInPPM < 1000000, "Value can't be more than 1000000");

        platformFeeInPPM = valueInPPM;
    }

    function totalSupply() public view returns (uint){
        return _carIdCounter.current();
    }
    
    function getCarToRentForId(uint256 carId) public view returns (CarToRent memory) {
        return idToCarToRent[carId];
    }

    function getRentCarRequestForId(uint256 carId) public view returns (RentCarRequest memory) {
        return idToRentCarRequest[carId];
    }

    function addCar(string memory tokenUri, uint256 pricePerDayInUsdCents) public returns (uint) {
        require(pricePerDayInUsdCents > 0, "Make sure the price isn't negative");

        _carIdCounter.increment();
        uint256 newCarId = _carIdCounter.current();
        
        _safeMint(msg.sender, newCarId);
        _setTokenURI(newCarId, tokenUri);
        
        createCarToken(newCarId, pricePerDayInUsdCents);

        return newCarId;
    }

    function createCarToken(uint256 carId, uint256 pricePerDayInUsdCents) private {
        //Just sanity check
        require(pricePerDayInUsdCents > 0, "Make sure the price isn't negative");

        //Update the mapping of carId's to Token details, useful for retrieval functions
        idToCarToRent[carId] = CarToRent(
            carId,
            payable(msg.sender),
            pricePerDayInUsdCents,
            true
        );

        _approve(address(this), carId);
        //_transfer(msg.sender, address(this), carId);
        
        emit CarAddedSuccess(
            carId,
            msg.sender,
            pricePerDayInUsdCents,
            true
        );
    }

    function burnCar(uint256 carId) public {        
        require(_exists(carId), "Token does not exist");
        require(ownerOf(carId) == msg.sender, "Only owner of the car can burn token");
        _burn(carId);
        delete idToCarToRent[carId];
    }
        
    //This will return all the NFTs currently listed to be sold on the marketplace
    function getAllCars() public view returns (CarToRent[] memory) {
        CarToRent[] memory tokens = new CarToRent[](totalSupply());
        
        for(uint i=0; i<totalSupply(); i++)
        {
            tokens[i] =  idToCarToRent[i + 1];
        }

        return tokens;
    }

    function isCarAvailable(uint256 carId, address sender) private view returns (bool) {
        return idToCarToRent[carId].currentlyListed 
               && ownerOf(carId) != sender
               && userOf(carId) == address(0);
    }
    
    function getAllAvailableCars() public view returns (CarToRent[] memory) {
        uint itemCount = 0;
        
        for(uint i=0; i < totalSupply(); i++)
        {
            uint currentId = i+1;
            if(isCarAvailable(currentId, msg.sender)){
                itemCount += 1;
            }
        }

        CarToRent[] memory result = new CarToRent[](itemCount);
        uint currentIndex = 0;

        for(uint i=0; i < totalSupply(); i++) {            
            uint currentId = i+1;
            if(isCarAvailable(currentId, msg.sender)){    
                CarToRent storage currentItem = idToCarToRent[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    function isMyCar(uint256 carId, address sender) private view returns (bool) {
        return ownerOf(carId) == sender;
    }

    function getMyCars() public view returns (CarToRent[] memory) {
        uint itemCount = 0;
        
        for(uint i=0; i < totalSupply(); i++)
        {
            uint currentId = i+1;
            if(isMyCar(currentId, msg.sender)){
                itemCount += 1;
            }
        }

        CarToRent[] memory result = new CarToRent[](itemCount);
        uint currentIndex = 0;

        for(uint i=0; i < totalSupply(); i++) {            
            uint currentId = i+1;
            if(isMyCar(currentId, msg.sender)){    
                CarToRent storage currentItem = idToCarToRent[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    function existRequestForCar(uint256 carId, address sender) private view returns (bool) {
        return isMyCar(carId, sender) && idToRentCarRequest[carId].carId > 0;
    }

    function getRequestsForMyCars() public view returns (RentCarRequest[] memory) {
        uint itemCount = 0;
        
        for(uint i=0; i < totalSupply(); i++)
        {
            uint currentId = i+1;
            if(existRequestForCar(currentId, msg.sender)){
                itemCount += 1;
            }
        }

        RentCarRequest[] memory result = new RentCarRequest[](itemCount);
        uint currentIndex = 0;

        for(uint i=0; i < totalSupply(); i++) {            
            uint currentId = i+1;
            if(existRequestForCar(currentId, msg.sender)){    
                RentCarRequest storage currentItem = idToRentCarRequest[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    function isRentedByMe(uint256 carId, address sender) private view returns (bool) {
        return userOf(carId) == sender;
    }

    function getCarsRentedByMe() public view returns (CarToRent[] memory) {
        uint itemCount = 0;
        
        for(uint i=0; i < totalSupply(); i++)
        {
            uint currentId = i+1;
            if(isRentedByMe(currentId, msg.sender)){
                itemCount += 1;
            }
        }

        CarToRent[] memory result = new CarToRent[](itemCount);
        uint currentIndex = 0;

        for(uint i=0; i < totalSupply(); i++) {            
            uint currentId = i+1;
            if(isRentedByMe(currentId, msg.sender)){    
                CarToRent storage currentItem = idToCarToRent[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    function isMyRequest(uint256 carId, address sender) private view returns (bool) {
        return idToRentCarRequest[carId].carId > 0 && idToRentCarRequest[carId].renter == sender ;
    }

    function getMyRequests() public view returns (RentCarRequest[] memory) {
        uint itemCount = 0;
        
        for(uint i=0; i < totalSupply(); i++)
        {
            uint currentId = i+1;
            if(isMyRequest(currentId, msg.sender)){
                itemCount += 1;
            }
        }

        RentCarRequest[] memory result = new RentCarRequest[](itemCount);
        uint currentIndex = 0;

        for(uint i=0; i < totalSupply(); i++) {            
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

    function rentCar(uint256 carId, uint daysForRent) public payable {
        require(msg.value > 0, "Rental fee must be greater than 0");
        //TODO require(_startDateTime > block.timestamp, "Start time must be in the future");        
        //TODO require(_startTimestamp < _endTimestamp, "End time must be after start time");   
        require(ownerOf(carId) != address(0), "Car does not exist");             
        require(ownerOf(carId) != msg.sender, "Owner of the car cannot rent his own car");

        uint totalPriceInUsdCents = idToCarToRent[carId].pricePerDayInUsdCents * daysForRent;
        uint totalPriceInEth = getEthFromUsd(totalPriceInUsdCents);
        require(abs(int(msg.value)-int(totalPriceInEth)) < 0.0001 * (1 ether), "Please submit the asking price in order to complete the purchase");

        //update the details of the token
        //idToCarToRent[carId].currentlyListed = false;
        idToRentCarRequest[carId] = RentCarRequest(
            carId,
            payable(msg.sender),
            daysForRent,
            totalPriceInUsdCents,
            0,0,"","",false
        );

        emit RentCarRequestCreatedSuccess(
            carId,
            msg.sender,
            daysForRent,
            totalPriceInUsdCents
        );        
    }

    function approveRentCar(uint256 carId) public {        
        require(ownerOf(carId) == msg.sender, "Only owner of the car can approve the request");

        //TODO uint256 daysForRent = (idToRentCarRequest[carId].endTimestamp - idToRentCarRequest[carId].startTimestamp) / 1 days;
        
        uint256 rentPeriodInSeconds = idToRentCarRequest[carId].daysForRent * SECONDS_IN_DAY;
        uint64 expires = uint64(block.timestamp + rentPeriodInSeconds);

        setUser(carId, idToRentCarRequest[carId].renter, expires);
        
        uint totalPriceInEth = getEthFromUsd(idToRentCarRequest[carId].totalPrice);
        uint priceToSendToHost = totalPriceInEth * platformFeeInPPM / 1000000;
        require(payable(ownerOf(carId)).send(priceToSendToHost));
        delete idToRentCarRequest[carId];        

        emit RentCarRequestApproved(
            carId,
            msg.sender
        );   
    }
    
    function rejectRentCar(uint256 carId) public {
        require(ownerOf(carId) == msg.sender, "Only owner of the car can reject the request");

        uint totalPriceInEth = getEthFromUsd(idToRentCarRequest[carId].totalPrice);
        require(idToRentCarRequest[carId].renter.send(totalPriceInEth));
        delete idToRentCarRequest[carId];

        emit RentCarRequestRejected(
            carId,
            msg.sender
        );   
    }

    function withdrawTips() public {
        require(address(this).balance > 0, "There is no commission to withdraw");        
        require(payable(owner()).send(address(this).balance));
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
}
