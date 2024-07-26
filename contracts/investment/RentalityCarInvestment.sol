// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import './IRentalityGeoParser.sol';
import '../proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../abstract/IRentalityGeoService.sol';
import "../payments/RentalityCurrencyConverter.sol";


contract RentalityCarInvestment is Initializable, UUPSAccess {
    CreateInvestmentRequest public  cars;
    ERC721 public nft;
    RentalityCurrencyConverter private converter;

    mapping(uint => uint) public balancesInEth;
    mapping(uint => bool) public created;

    function invest(uint carId) public payable {
        if (!created[carId]) {
            uint currentBalance = balancesInEth[carId];
            uint amountInUsd = converter.getToUsdWithCache(address(0), currentBalance);

            if(amountInUsd < cars.cars[carId].priceInUsd) {
                uint currentBalance = balancesInEth[carId];
                uint amountInUsd = converter.getToUsdWithCache(address(0), msg.value);
                balancesInEth[carId] = currentBalance + amountInUsd;
            }
            created[carId] = true;

        }

    }

    function claim()  {
        
    }

    /// @notice Initializes the contract with the specified addresses for user service and geolocation parser.
    /// @param _userService The address of the user service contract.
    /// @param _geoParser The address of the geolocation parser contract.
    function initialize(CreateInvestmentRequest memory _cars) public initializer {
        userService = IRentalityAccessControl(_userService);
        cars = _cars;

    }
}
