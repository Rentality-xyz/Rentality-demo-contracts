// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import './IRentalityGeoParser.sol';
import '../proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../abstract/IRentalityGeoService.sol';


contract RentalityInvestmentAggregator is Initializable, UUPSAccess {
    uint public investmentId;

    function createCarInvestment(CreateInvestmentRequest memory cars) public {

    }

    /// @notice Initializes the contract with the specified addresses for user service and geolocation parser.
    /// @param _userService The address of the user service contract.
    /// @param _geoParser The address of the geolocation parser contract.
    function initialize(address _userService, address _geoParser) public initializer {
        userService = IRentalityAccessControl(_userService);
        geoParser = IRentalityGeoParser(_geoParser);
    }
}
