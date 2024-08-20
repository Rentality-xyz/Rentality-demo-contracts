// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import '../proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import "../RentalityCarToken.sol";
import "../RentalityUserService.sol";

/// @title Rentality Geo Service Contract
/// @notice This contract provides geolocation services.
/// @dev It interacts with an external geolocation API and stores the results for cars.
contract RentalityReferralProgram is Initializable, UUPSAccess {


    mapping(address => bytes32) public referralHash;
    mapping(address => uint) public addressToPoints;
    mapping(bytes32 => address) private hashToOwner;
    mapping(bytes4 => mapping(address => bool)) private selectorToPassedAddress;
    mapping(bytes4 => uint) private selectorToPoints;

    RentalityCarToken private carToken;

    function generateReferralHash() public {
        bytes32 hash = createReferralHash();
        hashToOwner[hash] = tx.origin;
        referralHash[tx.origin] = hash;
    }

    function createReferralHash() internal view returns (bytes32) {
        return keccak256(abi.encode(this.generateReferralHash.selector, tx.origin));

    }

    function passReferralProgram(bytes4 selector, bytes32 hash) public {
        if (hash == bytes32(0))
            return;
        require(userService.isManager(msg.sender), "only Manager");
        if (selector == RentalityUserService(address(userService)).setKYCInfo.selector)
            require(!userService.isGuest(tx.origin), "already guest");
        else require(!userService.isHost(tx.origin), "already host");
        uint points = selectorToPoints[selector];
        require(points != 0, "program not exists");
        address owner = hashToOwner[hash];
        require(owner != address(0), "wrong hash");
        require(!selectorToPassedAddress[selector][tx.origin], "already passed");
        require(createReferralHash() != hash, "own hash");
        addressToPoints[owner] += points;
        addressToPoints[tx.origin] += points;
        selectorToPassedAddress[selector][tx.origin] = true;
    }

    function initialize(address _userService, address _carService) public virtual initializer {
        userService = IRentalityAccessControl(_userService);
        carToken = RentalityCarToken(_carService);
        RentalityUserService userServiceAddress = RentalityUserService(_userService);

        selectorToPoints[userServiceAddress.setKycCommission.selector] = 100;
        selectorToPoints[carToken.addCar.selector] = 900;
    }
}