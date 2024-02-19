// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import './libs/RentalityUtils.sol';
import './Schemas.sol';
import './IRentalityGeoService.sol';
import '@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol';
import './IRentalityGeoServiceParser.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
//#GEO sepolia
//CHAINLINK_ORACLE="0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD"
//CHAINLINK_TOKEN="0x779877A7B0D9E8603169DdbD7836e478b4624789"

/// @title Rentality Geo Parser Contract
/// @notice This contract provides geolocation services using Chainlink oracles.
/// @dev It interacts with an external geolocation API and stores the results for cars.
contract RentalityGeoParser is ChainlinkClient, Ownable, IRentalityGeoParser {
  using Chainlink for Chainlink.Request;

  /// @notice Chainlink job ID for the geolocation API.
  bytes32 private jobId;

  /// @notice Fee required for Chainlink requests.
  uint256 private fee;

  /// @notice Mapping to store the relationship between request ID and car ID.
  mapping(bytes32 => uint256) public requestIdToCarId;

  /// @notice Mapping to store geolocation response for each car ID.
  mapping(uint256 => string) public carIdToGeolocationResponse;

  constructor(address linkToken, address chainLinkOracle) {
    setChainlinkToken(linkToken);
    setChainlinkOracle(chainLinkOracle);
    jobId = '7d80a6386ef543a3abb52817f6707e3b';
    fee = (1 * LINK_DIVISIBILITY) / 10;
  }

  function getUrl(string memory addr, string memory key) public pure returns (string memory) {
    string memory urlApi = string.concat(
      'https://rentality-location-service-dq3ggp3yqq-lm.a.run.app/geolocation?address=',
      RentalityUtils.urlEncode(addr),
      '&key=',
      RentalityUtils.urlEncode(key)
    );
    return urlApi;
  }
  /// @notice Executes a Chainlink request for geolocation data.
  /// @param addr The address for geolocation lookup.
  /// @param key The API key for accessing the geolocation service.
  /// @param carId The ID of the car for which geolocation is requested.
  /// @return requestId The ID of the Chainlink request.
  function executeRequest(
    string memory addr,
    string memory,
    string memory,
    string memory key,
    uint256 carId
  ) public returns (bytes32 requestId) {
    // Build the URL for the geolocation API request.
    string memory urlApi = string.concat(
      'https://rentality-location-service-dq3ggp3yqq-lm.a.run.app/geolocation?address=',
      RentalityUtils.urlEncode(addr),
      '&key=',
      RentalityUtils.urlEncode(key)
    );

    // Build the Chainlink request.
    Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

    req.add('get', urlApi);
    req.add('path', 'resultInOneLine');

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
    require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
  }

  /// @notice Function to parse the geolocation response and store parsed data.
  /// @param carId The ID of the car for which geolocation is parsed.
  /// @return Parsed geolocation data for the specified car ID.
  function parseGeoResponse(uint256 carId) public view returns (Schemas.ParsedGeolocationData memory) {
    string memory response = carIdToGeolocationResponse[carId];

    //        require(bytes(response).length > 0, 'Response is not exist.');

    string[] memory pairs = RentalityUtils.splitString(response, bytes('|'));

    Schemas.ParsedGeolocationData memory result;
    for (uint256 i = 0; i < pairs.length; i++) {
      string[] memory keyValue = RentalityUtils.splitKeyValue(pairs[i]);
      string memory key = keyValue[0];
      string memory value = keyValue[1];
      if (RentalityUtils.compareStrings(key, 'status')) {
        result.status = value;
      } else if (RentalityUtils.compareStrings(key, 'locationLat')) {
        result.locationLat = value;
      } else if (RentalityUtils.compareStrings(key, 'locationLng')) {
        result.locationLng = value;
      } else if (RentalityUtils.compareStrings(key, 'northeastLat')) {
        result.northeastLat = value;
      } else if (RentalityUtils.compareStrings(key, 'northeastLng')) {
        result.northeastLng = value;
      } else if (RentalityUtils.compareStrings(key, 'southwestLat')) {
        result.southwestLat = value;
      } else if (RentalityUtils.compareStrings(key, 'southwestLng')) {
        result.southwestLng = value;
      } else if (RentalityUtils.compareStrings(key, 'locality')) {
        result.city = value;
      } else if (RentalityUtils.compareStrings(key, 'adminAreaLvl1')) {
        result.state = value;
      } else if (RentalityUtils.compareStrings(key, 'country')) {
        result.country = value;
      } else if (RentalityUtils.compareStrings(key, 'timeZoneID')) {
        result.timeZoneId = value;
      }
    }

    bool coordinatesAreValid = RentalityUtils.checkCoordinates(
      result.locationLat,
      result.locationLng,
      result.northeastLat,
      result.northeastLng,
      result.southwestLat,
      result.southwestLng
    );

    result.validCoordinates = coordinatesAreValid;
    return result;
  }
}
