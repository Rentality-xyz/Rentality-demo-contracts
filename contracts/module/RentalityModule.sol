// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721URIStorageUpgradeable, ERC721Upgradeable, IERC721Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

abstract contract RentalityModule is 
    ERC721URIStorageUpgradeable, 
    OwnableUpgradeable, 
    ReentrancyGuardUpgradeable,
    PausableUpgradeable 
{
    event AssetCreated(uint256 indexed tokenId, address indexed owner, uint256 price);
    event AssetRented(uint256 indexed tokenId, address indexed renter, address indexed owner, uint256 startTime, uint256 endTime, uint256 rentId);
    event AssetClaimed(uint256 indexed tokenId, address indexed owner, uint256 rentId);
    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
    event AssetPriceUpdated(uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice);
    event RentalApproved(uint256 indexed tokenId, address indexed approver);

    struct RentData {
        address renter;      
        address owner;      
        uint256 startTime;  
        uint256 endTime;
        bool isFinished;
        bool approved;
        uint256 rentId;
    }

 
    uint256 public tokenIdCounter;
    uint256 public rentIdCounter;
    uint256 public platformFee; 
    uint256 public constant MAX_PLATFORM_FEE = 1000;
    uint256 public constant MIN_RENTAL_DURATION = 1 hours;
    uint256 public constant MAX_RENTAL_DURATION = 365 days;
    

    bool public requireApprovalForRental;

    mapping(uint256 => RentData) public activeRentals;      
    mapping(uint256 => bool) public isRented;
    mapping(uint256 => uint256) public assetPrice;
    mapping(uint256 => address) public realAssetOwner;
    mapping(uint256 => uint256) public rentIdToTokenId;
    mapping(address => uint256[]) public userRentedAssets;   
    mapping(address => uint256[]) public userOwnedAssets;
    mapping(uint => uint) private rentIdPayedInNative;
    
    // Modifiers
    modifier onlyAssetOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not asset owner/approved");
        _;
    }
    
    modifier onlyRentalOwner(uint256 tokenId) {
        require(_msgSender() == activeRentals[tokenId].owner, "Not rental owner");
        _;
    }
    
    modifier rentalNotActive(uint256 tokenId) {
        require(!isRented[tokenId] || activeRentals[tokenId].endTime <= block.timestamp, "Rental is active");
        _;
    }
    
    modifier validDuration(uint256 duration) {
        require(duration >= MIN_RENTAL_DURATION, "Duration too short");
        require(duration <= MAX_RENTAL_DURATION, "Duration too long");
        _;
    }
    
    modifier validPrice(uint256 price) {
        require(price > 0, "Price must be greater than 0");
        _;
    }

    function initialize(
        string memory name, 
        string memory symbol, 
        uint256 _platformFee
    ) public initializer {
        __ERC721_init(name, symbol);
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        
        require(_platformFee <= MAX_PLATFORM_FEE, "Platform fee too high");
        platformFee = _platformFee;
        tokenIdCounter = 1;
        rentIdCounter = 1;
        requireApprovalForRental = true; 
    }

    function createAsset(address to, uint256 price) 
        public 
        virtual 
        validPrice(price)
        whenNotPaused 
    {
        require(to != address(0), "Invalid address");
        require(price > 0, "Price must be greater than 0");
        
        _safeMint(to, tokenIdCounter);
        assetPrice[tokenIdCounter] = price;
        realAssetOwner[tokenIdCounter] = to;
        _addToUserAssets(to, tokenIdCounter, true);
        
        emit AssetCreated(tokenIdCounter, to, price);
        tokenIdCounter++;
    }


    function createAsset(address to, uint256 price, bytes memory _data) 
        public 
        virtual 
    {
        createAsset(to, price);
    }


    function rentOut(
        uint256 tokenId,
        uint256 duration
    ) 
        public 
        payable 
        virtual 
        nonReentrant
        onlyAssetOwner(tokenId)
        rentalNotActive(tokenId)
        validDuration(duration)
        whenNotPaused 
    {
        address renter = msg.sender;
        require(renter != address(0), "Invalid renter address");
        require(renter != ownerOf(tokenId), "Cannot rent to self");
        require(msg.value >= assetPrice[tokenId], "Insufficient payment");

        _rentOut(tokenId, duration, bytes(""));
    }

    function rentOut(
        uint256 tokenId,
        uint256 duration,
        bytes memory _data
    ) 
        public 
        payable 
        virtual 
    {
        rentOut(tokenId, duration);
    }

    
    function _rentOut(uint256 tokenId, uint256 duration, bytes memory _data) internal {
        address renter = _msgSender();
        address currentOwner = ownerOf(tokenId);
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;
        
        activeRentals[tokenId] = RentData({
            renter: renter,
            owner: currentOwner,
            startTime: startTime,
            endTime: endTime,
            isFinished: false,
            approved: !requireApprovalForRental,
            rentId: rentIdCounter
        });

        isRented[tokenId] = true;
        rentIdToTokenId[rentIdCounter] = tokenId;
        
        _transfer(currentOwner, renter, tokenId);
        
        _removeFromUserAssets(currentOwner, tokenId, true);
        _addToUserAssets(renter, tokenId, false);
        rentIdPayedInNative[rentIdCounter] = msg.value;

        emit AssetRented(tokenId, renter, currentOwner, startTime, endTime, rentIdCounter);
        rentIdCounter++;
    }

    // Function to approve a rental
    function approveRental(uint256 tokenId) 
        public 
        virtual 
        onlyRentalOwner(tokenId)
        whenNotPaused 
    {
        require(isRented[tokenId], "Rental does not exist");
        require(!activeRentals[tokenId].approved, "Rental already approved");
        require(activeRentals[tokenId].endTime > block.timestamp, "Rental already finished");
        
        activeRentals[tokenId].approved = true;
        emit RentalApproved(tokenId, msg.sender);
    }

    function claimBack(uint256 tokenId) 
        public 
        virtual 
        nonReentrant
        onlyRentalOwner(tokenId)
        whenNotPaused 
    {
        RentData storage rental = activeRentals[tokenId];
        require(rental.endTime <= block.timestamp && rental.approved && requireApprovalForRental , "Rental still active");
        require(!rental.isFinished, "Already claimed");

        address currentHolder = ownerOf(tokenId);
        address originalOwner = rental.owner;
        
        _transfer(currentHolder, originalOwner, tokenId);
        
        uint256 totalAmount = rentIdPayedInNative[rental.rentId];
        uint256 platformFeeAmount = (totalAmount * platformFee) / 10000; 
        uint256 ownerAmount = totalAmount - platformFeeAmount;
        
      
        if (ownerAmount > 0) {
            (bool success, ) = payable(originalOwner).call{value: ownerAmount}("");
            require(success, "Transfer to owner failed");
        }
        
        if (platformFeeAmount > 0) {
            (bool success, ) = payable(owner()).call{value: platformFeeAmount}("");
            require(success, "Transfer to platform failed");
        }
        
        
        rental.isFinished = true;
        isRented[tokenId] = false;
        
     
        _removeFromUserAssets(rental.renter, tokenId, false);
        _addToUserAssets(originalOwner, tokenId, true);
        
        emit AssetClaimed(tokenId, originalOwner, rentIdToTokenId[tokenId]);
    }

       function claimBack(uint256 tokenId, bytes memory _data) 
        public 
        virtual 
    {
            claimBack(tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
    
        if (isRented[tokenId]) {
            RentData storage rental = activeRentals[tokenId];
            
         
            if (rental.endTime > block.timestamp) {
                revert("Cannot transfer during active rental");
            }
            
           
            if (rental.endTime <= block.timestamp && !rental.isFinished) {
                require(from == rental.owner, "Only original owner can transfer after rental");
            }
        }
        
        super._transfer(from, to, tokenId);
        realAssetOwner[tokenId] = to;
    }

    function approve(address to, uint256 tokenId) 
        public 
        virtual 
        override(ERC721Upgradeable, IERC721Upgradeable)
        rentalNotActive(tokenId)
        whenNotPaused 
    {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) 
        public 
        virtual 
        override(ERC721Upgradeable, IERC721Upgradeable)
    {
        require(false, "not implemented");
    }

   
    function setPlatformFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_PLATFORM_FEE, "Platform fee too high");
        uint256 oldFee = platformFee;
        platformFee = newFee;
        emit PlatformFeeUpdated(oldFee, newFee);
    }
    
   
    function setRequireApprovalForRental(bool _requireApproval) external onlyOwner {
        requireApprovalForRental = _requireApproval;
    }
    
    function updateAssetPrice(uint256 tokenId, uint256 newPrice) 
        external 
        onlyAssetOwner(tokenId)
        validPrice(newPrice)
    {
        require(isRented[tokenId] == false, "not allowed during rent");
        
        uint256 oldPrice = assetPrice[tokenId];
        assetPrice[tokenId] = newPrice;
        emit AssetPriceUpdated(tokenId, oldPrice, newPrice);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }

  
    function getRentalInfo(uint256 tokenId) external view returns (RentData memory) {
        return activeRentals[tokenId];
    }
    
    function isRentalActive(uint256 tokenId) external view returns (bool) {
        return isRented[tokenId] && activeRentals[tokenId].endTime > block.timestamp;
    }
    
    function isRentalApproved(uint256 tokenId) external view returns (bool) {
        return activeRentals[tokenId].approved;
    }
    
    function getUserAssets(address user, bool owned) external view returns (uint256[] memory) {
        return owned ? userOwnedAssets[user] : userRentedAssets[user];
    }
    
    function getRentalDuration(uint256 tokenId) external view returns (uint256) {
        RentData memory rental = activeRentals[tokenId];
        if (rental.endTime > rental.startTime) {
            return rental.endTime - rental.startTime;
        }
        return 0;
    }


    function _addToUserAssets(address user, uint256 tokenId, bool isOwned) internal {
        if (isOwned) {
            userOwnedAssets[user].push(tokenId);
        } else {
            userRentedAssets[user].push(tokenId);
        }
    }
    
    function _removeFromUserAssets(address user, uint256 tokenId, bool isOwned) internal {
        uint256[] storage list = isOwned ? userOwnedAssets[user] : userRentedAssets[user];
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == tokenId) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    // Emergency functions
    function emergencyWithdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Emergency withdraw failed");
    }

    function assetOwner(uint256 tokenId) public view returns (address) {
        return realAssetOwner[tokenId];
    }
}