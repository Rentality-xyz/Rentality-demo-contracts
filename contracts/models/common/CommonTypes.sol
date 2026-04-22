// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct LocationInfo {
    string userAddress;
    string country;
    string state;
    string city;
    string latitude;
    string longitude;
    string timeZoneId;
}

struct SignedLocationInfo {
    LocationInfo locationInfo;
    bytes signature;
}

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
    string timeZoneId;
}

struct UserCurrencyInfo {
    address currency;
    string name;
    bool initialized;
}
