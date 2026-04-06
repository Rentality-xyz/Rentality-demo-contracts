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

