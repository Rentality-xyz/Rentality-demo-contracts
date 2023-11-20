// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RentalityUtils.sol";
import "./IRentalityCarToken.sol";


contract RentalityGeoService is ChainlinkClient, Ownable {
    using Chainlink for Chainlink.Request;

    bytes32 private jobId;
    uint256 private fee;

    mapping(bytes32 => uint256) public requestIdToCarId;
    mapping(uint256 => string) public carIdToGeolocationResponse;
    mapping(uint256 => ParsedGeolocationData) public carIdToParsedGeolocationData;


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


    constructor(address linkToken, address chainLinkOracle ) {
        setChainlinkToken(linkToken);
        setChainlinkOracle(chainLinkOracle);
        jobId = "7d80a6386ef543a3abb52817f6707e3b";
        fee = (1 * LINK_DIVISIBILITY) / 10;

    }

    function executeRequest(string memory addr, string memory key, uint256 carId) public returns (bytes32 requestId) {

        string memory urlApi = string.concat(
            "https://rentality-location-service-dq3ggp3yqq-lm.a.run.app/geolocation?address=",
            RentalityUtils.urlEncode(addr),
            "&location=0,0&key=",
            RentalityUtils.urlEncode(key)
        );

        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        req.add(
            "get",
            urlApi
        );

        req.add("path", "0,resultInOneLine");
        bytes32 reqId =  sendChainlinkRequest(req, fee);
        requestIdToCarId[reqId] = carId;
        return reqId;
    }

    function fulfill(
        bytes32 _requestId,
        string memory  _response
    ) public  recordChainlinkFulfillment(_requestId) {
        uint256 carId = requestIdToCarId[_requestId];
        carIdToGeolocationResponse[carId] = _response;
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

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

        bool coordinatesAreValid =
                            RentalityUtils.checkCoordinates(
                result.locationLat, result.locationLng, result.northeastLat,
                result.northeastLng, result.southwestLat, result.southwestLng
            );
        result.validCoordinates = coordinatesAreValid;
        carIdToParsedGeolocationData[carId] = result;
    }

    function getCarCoordinateValidity(uint256 carId) public view returns (bool) {
        return carIdToParsedGeolocationData[carId].validCoordinates;
    }

    function getCarCity(uint256 carId) public view returns (string memory) {
        return carIdToParsedGeolocationData[carId].city;
    }

    function getCarState(uint256 carId) public view returns (string memory) {
        return carIdToParsedGeolocationData[carId].state;
    }

    function getCarCountry(uint256 carId) public view returns (string memory) {
        return carIdToParsedGeolocationData[carId].country;
    }
}