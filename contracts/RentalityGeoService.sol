// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./RentalityUtils.sol";

/// @title Rentality Geo Service Contract
/// @notice This contract provides geolocation services using Chainlink oracles.
/// @dev It interacts with an external geolocation API and stores the results for cars.
//#GEO sepolia
//CHAINLINK_ORACLE="0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD"
//CHAINLINK_TOKEN="0x779877A7B0D9E8603169DdbD7836e478b4624789"
contract RentalityGeoService is ChainlinkClient, OwnableUpgradeable, UUPSUpgradeable {
    using Chainlink for Chainlink.Request;

    /// @notice Chainlink job ID for the geolocation API.
    bytes32 private jobId;

    /// @notice Fee required for Chainlink requests.
    uint256 private fee;

    /// @notice Mapping to store the relationship between request ID and car ID.
    mapping(bytes32 => uint256) public requestIdToCarId;

    /// @notice Mapping to store geolocation response for each car ID.
    mapping(uint256 => string) public carIdToGeolocationResponse;

    /// @notice Mapping to store parsed geolocation data for each car ID.
    mapping(uint256 => ParsedGeolocationData) public carIdToParsedGeolocationData;

    /// @dev Struct to store parsed geolocation data.
    struct ParsedGeolocationData {
        string status;
        bool validCoordinates;
        string locationLat;
        string locationLng;
        string northeastLat;
        string northeastLng;
        string southwestLat;
        string southwestLng;
        string city;
        string state;
        string country;
    }

    /// @notice Function to execute a Chainlink request for geolocation data.
    /// @param addr The address for geolocation lookup.
    /// @param key The API key for accessing the geolocation service.
    /// @param carId The ID of the car for which geolocation is requested.
    /// @return requestId The ID of the Chainlink request.
    function executeRequest(string memory addr, string memory key, uint256 carId) public returns (bytes32 requestId) {
        // Build the URL for the geolocation API request.
        string memory urlApi = string.concat(
            "https://rentality-location-service-dq3ggp3yqq-lm.a.run.app/geolocation?address=",
            RentalityUtils.urlEncode(addr),
            "&location=0,0&key=",
            RentalityUtils.urlEncode(key)
        );

        // Build the Chainlink request.
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        req.add("get", urlApi);
        req.add("path", "0,resultInOneLine");

        // Send the Chainlink request and store the request ID.
        bytes32 reqId = sendChainlinkRequest(req, fee);
        requestIdToCarId[reqId] = carId;
        return reqId;
    }

    /// @notice Function called by Chainlink when the request is fulfilled.
    /// @param _requestId The ID of the Chainlink request.
    /// @param _response The geolocation response from the API.
    function fulfill(bytes32 _requestId, string memory _response) public recordChainlinkFulfillment(_requestId) {
        uint256 carId = requestIdToCarId[_requestId];
        carIdToGeolocationResponse[carId] = _response;
    }

    /// @notice Function to withdraw LINK tokens from the contract (onlyOwner).
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    /// @notice Function to parse the geolocation response and store parsed data.
    /// @param carId The ID of the car for which geolocation is parsed.
    function parseGeoResponse(uint256 carId) public {
        string memory response = carIdToGeolocationResponse[carId];
        string[] memory pairs = RentalityUtils.splitString(response);

        ParsedGeolocationData memory result;

        for (uint256 i = 0; i < pairs.length; i++) {
            string[] memory keyValue = RentalityUtils.splitKeyValue(pairs[i]);
            string memory key = keyValue[0];
            string memory value = keyValue[1];
            if (RentalityUtils.compareStrings(key, "status")) {
                result.status = value;
            } else if (RentalityUtils.compareStrings(key, "locationLat")) {
                result.locationLat = value;
            } else if (RentalityUtils.compareStrings(key, "locationLng")) {
                result.locationLng = value;
            } else if (RentalityUtils.compareStrings(key, "northeastLat")) {
                result.northeastLat = value;
            } else if (RentalityUtils.compareStrings(key, "northeastLng")) {
                result.northeastLng = value;
            } else if (RentalityUtils.compareStrings(key, "southwestLat")) {
                result.southwestLat = value;
            } else if (RentalityUtils.compareStrings(key, "southwestLng")) {
                result.southwestLng = value;
            } else if (RentalityUtils.compareStrings(key, "locality")) {
                result.city = value;
            } else if (RentalityUtils.compareStrings(key, "adminAreaLvl1")) {
                result.state = value;
            } else if (RentalityUtils.compareStrings(key, "country")) {
                result.country = value;
            }
        }

        bool coordinatesAreValid = RentalityUtils.checkCoordinates(
            result.locationLat, result.locationLng, result.northeastLat,
            result.northeastLng, result.southwestLat, result.southwestLng
        );

        result.validCoordinates = coordinatesAreValid;
        carIdToParsedGeolocationData[carId] = result;
    }

    /// @notice Function to get the validity of geolocation coordinates for a car.
    /// @param carId The ID of the car.
    /// @return validCoordinates A boolean indicating the validity of coordinates.
    function getCarCoordinateValidity(uint256 carId) public view returns (bool) {
        return carIdToParsedGeolocationData[carId].validCoordinates;
    }

    /// @notice Function to get the city of geolocation for a car.
    /// @param carId The ID of the car.
    /// @return city The city name.
    function getCarCity(uint256 carId) public view returns (string memory) {
        return carIdToParsedGeolocationData[carId].city;
    }

    /// @notice Function to get the state of geolocation for a car.
    /// @param carId The ID of the car.
    /// @return state The state name.
    function getCarState(uint256 carId) public view returns (string memory) {
        return carIdToParsedGeolocationData[carId].state;
    }

    /// @notice Function to get the country of geolocation for a car.
    /// @param carId The ID of the car.
    /// @return country The country name.
    function getCarCountry(uint256 carId) public view returns (string memory) {
        return carIdToParsedGeolocationData[carId].country;
    }

    //   @dev Checks whether the upgrade to a new implementation is authorized.
    //  @param newImplementation The address of the new implementation contract.
    //  Requirements:
    //  - The owner must have authorized the upgrade.
    function _authorizeUpgrade(address newImplementation) internal override
    {
        _checkOwner();
    }

    /// @notice Constructor to initialize Chainlink settings.
    /// @param linkToken The address of the LINK token contract.
    /// @param chainLinkOracle The address of the Chainlink oracle.
    function initialize(address linkToken, address chainLinkOracle) public initializer {

        setChainlinkToken(linkToken);
        setChainlinkOracle(chainLinkOracle);
        jobId = "7d80a6386ef543a3abb52817f6707e3b";
        fee = (1 * LINK_DIVISIBILITY) / 10;

        __Ownable_init();
    }
}

