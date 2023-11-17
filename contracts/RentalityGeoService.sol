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
    IRentalityCarToken private carService;
    uint256 private requests;

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
        carService = IRentalityCarToken(address(0));
        requests = 1;
    }

    modifier isUpdated()
    {
        require(address (0) != address (carService));
        _;
    }

    function updateCarService(address carToken) public
    {
        require(tx.origin == owner());

        carService = IRentalityCarToken(carToken);
    }

    function executeRequest(string memory addr, string memory key, uint256 carId)
    isUpdated public returns (bytes32 requestId) {

        require(msg.sender == address (carService));

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

        bytes32 reqId = keccak256(abi.encodePacked(this, requests));

        req.addBytes("reqId", RentalityUtils.toBytes(reqId));

        sendChainlinkRequest(req, fee);

        requestIdToCarId[reqId] = carId;
        requests += 1;

        return reqId;
    }

    function handleResponse(ParsedGeolocationData memory data, uint256 carId, bytes32 reqId) isUpdated public onlyOwner
    {
        require(requestIdToCarId[reqId] == carId);
        carIdToParsedGeolocationData[carId] = data;
        carService.verifyGeo(carId);

    }

    function fulfill(
        bytes32 _requestId,
        string memory  _response
    ) public  recordChainlinkFulfillment(_requestId) {
        //do nothing
    }


    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
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