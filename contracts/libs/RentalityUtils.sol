// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '../Schemas.sol';
import '../RentalityUserService.sol';
import '../RentalityCarToken.sol';
import '../abstract/IRentalityGeoService.sol';
import '../RentalityTripService.sol';
import '../payments/RentalityCurrencyConverter.sol';
import '../payments/RentalityPaymentService.sol';
import {RentalityContract} from '../RentalityGateway.sol';
import {RentalityCarDelivery} from '../features/RentalityCarDelivery.sol';
import {RentalityInsurance} from '../payments/RentalityInsurance.sol';
import {RentalityReferralProgram} from '../features/refferalProgram/RentalityReferralProgram.sol';

import {RentalityClaimService} from '../features/RentalityClaimService.sol';
import {RentalityDimoService} from '../features/RentalityDimoService.sol';
import {RentalityPromoService} from '../features/RentalityPromo.sol';
/// @title RentalityUtils Library
/// @notice
/// This library provides utility functions for handling coordinates, string manipulation,
/// and parsing responses related to geolocation data. It includes functions for checking
/// coordinates within a specified bounding box, parsing strings, converting between data types,
/// and URL encoding. The library is used in conjunction with other Rentality contracts.
library RentalityUtils {
  // Constant multiplier for converting decimal coordinates to integers
  uint256 constant multiplier = 10 ** 7;

  /// @notice Checks if a set of coordinates falls within a specified bounding box.
  /// @param locationLat Latitude of the location to check.
  /// @param locationLng Longitude of the location to check.
  /// @param northeastLat Latitude of the northeast corner of the bounding box.
  /// @param northeastLng Longitude of the northeast corner of the bounding box.
  /// @param southwestLat Latitude of the southwest corner of the bounding box.
  /// @param southwestLng Longitude of the southwest corner of the bounding box.
  /// @return Returns true if the coordinates are within the bounding box, false otherwise.
  function checkCoordinates(
    string memory locationLat,
    string memory locationLng,
    string memory northeastLat,
    string memory northeastLng,
    string memory southwestLat,
    string memory southwestLng
  ) external pure returns (bool) {
    int256 lat = parseInt(locationLat);
    int256 lng = parseInt(locationLng);
    int256 neLat = parseInt(northeastLat);
    int256 neLng = parseInt(northeastLng);
    int256 swLat = parseInt(southwestLat);
    int256 swLng = parseInt(southwestLng);

    return (lat >= swLat && lat <= neLat && lng >= swLng && lng <= neLng);
  }

  /// @notice Parses an integer from a string.
  /// @param _a The input string to parse.
  /// @return Returns the parsed integer value.
  function parseInt(string memory _a) public pure returns (int256) {
    bytes memory bresult = bytes(_a);
    int256 mint = 0;
    bool decimals = false;
    for (uint i = 0; i < bresult.length; i++) {
      if ((uint8(bresult[i]) >= 48) && (uint8(bresult[i]) <= 57)) {
        if (decimals) {
          if (i - 1 - indexOf(bresult, '.') > 6) break;
          mint = mint * 10 + int256(uint256(uint8(bresult[i])) - 48);
        } else {
          mint = mint * 10 + int256(uint256(uint8(bresult[i])) - 48);
        }
      } else if (uint8(bresult[i]) == 46) decimals = true;
    }
    if (indexOf(bresult, '-') == 0) {
      return -mint * int256(multiplier);
    }
    return mint * int256(multiplier);
  }

  /// @notice Finds the index of a substring in a given string.
  /// @param haystack The string to search within.
  /// @param needle The substring to search for.
  /// @return Returns the index of the first occurrence of the substring, or the length of the string if not found.
  function indexOf(bytes memory haystack, string memory needle) internal pure returns (uint) {
    bytes memory bneedle = bytes(needle);
    if (bneedle.length > haystack.length) {
      return haystack.length;
    }

    bool found = false;
    uint i;
    for (i = 0; i <= haystack.length - bneedle.length; i++) {
      found = true;
      for (uint j = 0; j < bneedle.length; j++) {
        if (haystack[i + j] != bneedle[j]) {
          found = false;
          break;
        }
      }
      if (found) {
        break;
      }
    }
    return i;
  }

  /// @notice Converts a string to lowercase.
  /// @param str The input string to convert.
  /// @return Returns the lowercase version of the input string.
  function toLower(string memory str) public pure returns (string memory) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      // Uppercase character...
      if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
        // So we add 32 to make it lowercase
        bLower[i] = bytes1(uint8(bStr[i]) + 32);
      } else {
        bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }

  /// @notice Checks if a string contains a specific word.
  /// @param where The string to search within.
  /// @param what The word to search for.
  /// @return found Returns true if the word is found, false otherwise.
  function containWord(string memory where, string memory what) public pure returns (bool found) {
    bytes memory whatBytes = bytes(what);
    bytes memory whereBytes = bytes(where);

    if (whereBytes.length < whatBytes.length) {
      return false;
    }

    found = false;
    for (uint i = 0; i <= whereBytes.length - whatBytes.length; i++) {
      bool flag = true;
      for (uint j = 0; j < whatBytes.length; j++)
        if (whereBytes[i + j] != whatBytes[j]) {
          flag = false;
          break;
        }
      if (flag) {
        found = true;
        break;
      }
    }
    return found;
  }

  /// @notice Generates a hash from a string.
  /// @param str The input string to hash.
  /// @return Returns the keccak256 hash of the input string.
  function getHashFromString(string memory str) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(str));
  }

  /// @notice Calculates the ceiling of the division of two numbers.
  /// @param startDateTime The numerator of the division.
  /// @param endDateTime The denominator of the division.
  /// @return Returns the result of the division rounded up to the nearest whole number.
  function getCeilDays(uint64 startDateTime, uint64 endDateTime) internal pure returns (uint64) {
    uint64 duration = endDateTime - startDateTime;
    return uint64(Math.ceilDiv(duration, 1 days));
  }

  /// not using
  /// @notice Parses a response string containing geolocation data.
  /// @param response The response string to parse.
  /// @return result Parsed geolocation data in RentalityGeoService.ParsedGeolocationData structure.
  // function parseResponse(string memory response) public pure returns (Schemas.ParsedGeolocationData memory) {
  //   Schemas.ParsedGeolocationData memory result;

  //   string[] memory pairs = splitString(response, bytes('|'));
  //   for (uint256 i = 0; i < pairs.length; i++) {
  //     string[] memory keyValue = splitKeyValue(pairs[i]);
  //     string memory key = keyValue[0];
  //     string memory value = keyValue[1];
  //     if (compareStrings(key, 'status')) {
  //       result.status = value;
  //     } else if (compareStrings(key, 'locationLat')) {
  //       result.locationLat = value;
  //     } else if (compareStrings(key, 'locationLng')) {
  //       result.locationLng = value;
  //     } else if (compareStrings(key, 'northeastLat')) {
  //       result.northeastLat = value;
  //     } else if (compareStrings(key, 'northeastLng')) {
  //       result.northeastLng = value;
  //     } else if (compareStrings(key, 'southwestLat')) {
  //       result.southwestLat = value;
  //     } else if (compareStrings(key, 'southwestLng')) {
  //       result.southwestLng = value;
  //     } else if (compareStrings(key, 'locality')) {
  //       result.city = value;
  //     } else if (compareStrings(key, 'adminAreaLvl1')) {
  //       result.state = value;
  //     } else if (compareStrings(key, 'country')) {
  //       result.country = value;
  //     }
  //   }

  //   return result;
  // }

  /// @notice Splits a string into an array of substrings based on a delimiter.
  /// @param input The input string to split.
  /// @return parts Array of substrings.
  function splitString(string memory input, bytes memory delimiterBytes) internal pure returns (string[] memory) {
    bytes memory inputBytes = bytes(input);

    uint256 delimiterCount = 0;
    for (uint256 i = 0; i < inputBytes.length; i++) {
      if (inputBytes[i] == delimiterBytes[0]) {
        delimiterCount++;
      }
    }

    string[] memory parts = new string[](delimiterCount + 1);

    uint256 partIndex = 0;
    uint256 startNewString = 0;

    for (uint256 i = 0; i < inputBytes.length; i++) {
      if (inputBytes[i] == delimiterBytes[0]) {
        bytes memory newString = new bytes(i - startNewString);
        uint256 newStringIndex = 0;
        for (uint256 j = startNewString; j < i; j++) {
          newString[newStringIndex] = inputBytes[j];
          newStringIndex++;
          startNewString++;
        }
        startNewString++;
        parts[partIndex] = string(newString);
        partIndex++;
      }
    }
    // get last part
    if (startNewString < inputBytes.length) {
      bytes memory lastString = new bytes(inputBytes.length - startNewString);
      for (uint256 j = startNewString; j < inputBytes.length; j++) {
        lastString[j - startNewString] = inputBytes[j];
      }
      parts[partIndex] = string(lastString);
    }

    return parts;
  }

  /// @notice Splits a key-value pair string into an array of key and value.
  /// @param input The input string to split.
  /// @return parts Array containing key and value.
  function splitKeyValue(string memory input) internal pure returns (string[] memory) {
    bytes memory inputBytes = bytes(input);
    bytes memory delimiterBytes = bytes('^');

    uint256 delimiterIndex = 0;
    for (uint256 i = 0; i < inputBytes.length; i++) {
      if (inputBytes[i] == delimiterBytes[0]) {
        delimiterIndex = i;
      }
    }

    string[] memory parts = new string[](2);
    bytes memory keyString = new bytes(delimiterIndex);

    for (uint256 i = 0; i < delimiterIndex; i++) {
      keyString[i] = inputBytes[i];
    }
    parts[0] = string(keyString);

    bytes memory valueString = new bytes(inputBytes.length - delimiterIndex - 1);

    uint256 startValueString = 0;
    for (uint256 i = (delimiterIndex + 1); i < inputBytes.length; i++) {
      valueString[startValueString] = inputBytes[i];
      startValueString++;
    }

    parts[1] = string(valueString);

    return parts;
  }

  /// @notice Compares two strings for equality.
  /// @param a The first string.
  /// @param b The second string.
  /// @return Returns true if the strings are equal, false otherwise.
  function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(bytes(a)) == keccak256(bytes(b)));
  }

  /// @notice URL encodes a string.
  /// @param input The input string to encode.
  /// @return output The URL-encoded string.
  function urlEncode(string memory input) internal pure returns (string memory) {
    bytes memory inputBytes = bytes(input);
    string memory output = '';

    for (uint256 i = 0; i < inputBytes.length; i++) {
      bytes memory spaceBytes = bytes(' ');
      if (inputBytes[i] == spaceBytes[0]) {
        output = string(
          abi.encodePacked(
            output,
            '%',
            bytes1(uint8(inputBytes[i]) / 16 + 48),
            bytes1((uint8(inputBytes[i]) % 16) + 48)
          )
        );
      } else {
        output = string(abi.encodePacked(output, bytes1(inputBytes[i])));
      }
    }
    return output;
  }

  /// @dev Converts a bytes32 data to a bytes array.
  /// @param _data The input bytes32 data to convert.
  /// @return Returns the packed representation of the input data as a bytes array.
  function toBytes(bytes32 _data) public pure returns (bytes memory) {
    return abi.encodePacked(_data);
  }

  /// @notice Checks if a car is available for a specific user based on search parameters.
  /// @dev Determines availability based on several conditions, including ownership and search parameters.
  /// @param carId The ID of the car being checked.
  /// @param searchCarParams The parameters used to filter available cars.
  /// @return A boolean indicating whether the car is available for the user.
  function isCarAvailableForUser(
    uint256 carId,
    Schemas.SearchCarParams memory searchCarParams,
    address carServiceAddress,
    address geoServiceAddress
  ) public view returns (bool) {
    RentalityCarToken carService = RentalityCarToken(carServiceAddress);
    IRentalityGeoService geoService = IRentalityGeoService(geoServiceAddress);

    Schemas.CarInfo memory car = carService.getCarInfoById(carId);
    return
      (bytes(searchCarParams.brand).length == 0 || containWord(toLower(car.brand), toLower(searchCarParams.brand))) &&
      (bytes(searchCarParams.model).length == 0 || containWord(toLower(car.model), toLower(searchCarParams.model))) &&
      (bytes(searchCarParams.country).length == 0 ||
        containWord(toLower(geoService.getCarCountry(car.locationHash)), toLower(searchCarParams.country))) &&
      (bytes(searchCarParams.state).length == 0 ||
        containWord(toLower(geoService.getCarState(car.locationHash)), toLower(searchCarParams.state))) &&
      (bytes(searchCarParams.city).length == 0 ||
        containWord(toLower(geoService.getCarCity(car.locationHash)), toLower(searchCarParams.city))) &&
      (searchCarParams.yearOfProductionFrom == 0 || car.yearOfProduction >= searchCarParams.yearOfProductionFrom) &&
      (searchCarParams.yearOfProductionTo == 0 || car.yearOfProduction <= searchCarParams.yearOfProductionTo) &&
      (searchCarParams.pricePerDayInUsdCentsFrom == 0 ||
        car.pricePerDayInUsdCents >= searchCarParams.pricePerDayInUsdCentsFrom) &&
      (searchCarParams.pricePerDayInUsdCentsTo == 0 ||
        car.pricePerDayInUsdCents <= searchCarParams.pricePerDayInUsdCentsTo);
  }

  /// @dev Calculates the payments for a trip.
  /// @param carId The ID of the car.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param currency The currency to use for payment calculation.
  /// @param pickUpLocation lat and lon of pickUp and return locations.
  /// @param returnLocation lat and lon of pickUp and return locations.
  /// @return calculatePaymentsDTO An object containing payment details.
  function calculatePaymentsWithDelivery(
    RentalityContract memory addresses,
    uint carId,
    uint64 daysOfTrip,
    address currency,
    Schemas.LocationInfo memory pickUpLocation,
    Schemas.LocationInfo memory returnLocation,
    RentalityInsurance insuranceService,
    string memory promo,
    RentalityPromoService promoService
  ) public view returns (Schemas.CalculatePaymentsDTO memory) {
    uint64 deliveryFee = RentalityCarDelivery(addresses.adminService.getDeliveryServiceAddress())
      .calculatePriceByDeliveryDataInUsdCents(
        pickUpLocation,
        returnLocation,
        IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getCarLocationLatitude(
          addresses.carService.getCarInfoById(carId).locationHash
        ),
        IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getCarLocationLongitude(
          addresses.carService.getCarInfoById(carId).locationHash
        ),
        addresses.carService.getCarInfoById(carId).createdBy
      );
    return
      calculatePayments(
        addresses,
        carId,
        daysOfTrip,
        currency,
        deliveryFee,
        insuranceService,
        promo,
        promoService,
        tx.origin
      );
  }
  function calculatePayments(
    RentalityContract memory addresses,
    uint carId,
    uint64 daysOfTrip,
    address currency,
    uint64 deliveryFee,
    RentalityInsurance insuranceService,
    string memory promo,
    RentalityPromoService promoService,
    address user
  ) public view returns (Schemas.CalculatePaymentsDTO memory) {
    address carOwner = addresses.carService.ownerOf(carId);
    Schemas.CarInfo memory car = addresses.carService.getCarInfoById(carId);

    uint64 discount = uint64(promoService.getDiscountByPromo(promo, user));
     uint64 priceWithDiscount;
     priceWithDiscount = addresses.paymentService.calculateSumWithDiscount(
      addresses.carService.ownerOf(carId),
      daysOfTrip,
      car.pricePerDayInUsdCents
    );

    uint64 sumWithDiscount = addresses.paymentService.calculateSumWithDiscount(
      carOwner,
      daysOfTrip,
      car.pricePerDayInUsdCents
    );

    uint taxId = addresses.paymentService.defineTaxesType(address(addresses.carService), carId);

    (uint64 salesTaxes, uint64 govTax) = addresses.paymentService.calculateTaxes(
      taxId,
      daysOfTrip,
      sumWithDiscount + deliveryFee
    );

    uint64 priceBeforePromo = sumWithDiscount + salesTaxes + govTax + deliveryFee;

    uint64 discountedPrice = priceBeforePromo;
    if (discount > 0) {
      discountedPrice = priceBeforePromo - ((priceBeforePromo * discount) / 100);
    }

    uint totalPrice = car.securityDepositPerTripInUsdCents + discountedPrice;

    if (!insuranceService.isGuestHasInsurance(tx.origin)) {
      totalPrice += insuranceService.getInsurancePriceByCar(carId) * daysOfTrip;
    }

    (uint256 valueSumInCurrency, int rate, uint8 decimals) = addresses.currencyConverterService.getFromUsdLatest(
      currency,
      totalPrice
    );
    if(discount == 100) {
      valueSumInCurrency = 0;
    }

    return Schemas.CalculatePaymentsDTO(valueSumInCurrency, rate, decimals);
  }

  function validateTripRequest(
    RentalityContract memory addresses,
    address currencyType,
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime
  ) public view {
    require(addresses.userService.hasPassedKYCAndTC(tx.origin), 'KYC or TC not passed.');
    require(addresses.currencyConverterService.currencyTypeIsAvailable(currencyType), 'Token is not available.');
    require(addresses.carService.ownerOf(carId) != tx.origin, 'Car is not available for creator');
    require(!isCarUnavailable(addresses, carId, startDateTime, endDateTime), 'Unavailable for current date.');
  }

  // @dev Checks if a car has any active trips within the specified time range.
  // @param carId The ID of the car to check for availability.
  // @param startDateTime The start time of the time range.
  // @param endDateTime The end time of the time range.
  // @return A boolean indicating whether the car is unavailable during the specified time range.
  function isCarUnavailable(
    RentalityContract memory addresses,
    uint256 carId,
    uint64 startDateTime,
    uint64 endDateTime
  ) private view returns (bool) {
    uint [] memory activeTrips = addresses.tripService.getCarTrips(carId);
    for (uint256 i = 0; i < activeTrips.length; i++) {
      Schemas.Trip memory trip = addresses.tripService.getTrip(activeTrips[i]);
      Schemas.CarInfo memory car = addresses.carService.getCarInfoById(trip.carId);

      if (
        trip.carId == carId &&
        trip.endDateTime + car.timeBufferBetweenTripsInSec > startDateTime &&
        trip.startDateTime < endDateTime
      ) {
        Schemas.TripStatus tripStatus = trip.status;

        // Check if the trip is active (not in Created, Finished, or Canceled status).
        bool isActiveTrip = (tripStatus != Schemas.TripStatus.Created &&
          tripStatus != Schemas.TripStatus.Finished &&
          tripStatus != Schemas.TripStatus.Canceled);

        // Return true if an active trip is found.
        if (isActiveTrip) {
          return true;
        }
      }
    }

    // If no active trips are found, return false indicating the car is available.
    return false;
  }

  /// @notice Creates a payment information structure for a trip based on the provided parameters.
  /// @dev This function calculates various components of the payment including the base price, taxes, and additional fees.
  /// It also converts the total amount to the specified currency using the current exchange rate.
  /// @param addresses The Rentality contract instance containing service addresses.
  /// @param carId The ID of the car being rented.
  /// @param startDateTime The start time of the trip.
  /// @param endDateTime The end time of the trip.
  /// @param currencyType The type of currency in which the payment will be made (e.g., ETH, ERC20 token).
  /// @param pickUp The pick-up fee for the car.
  /// @param dropOf The drop-off fee for the car.
  /// @return A tuple containing the PaymentInfo structure and the total amount to be paid in the specified currency.
  function createPaymentInfo(
    RentalityContract memory addresses,
    uint256 carId,
    uint64 startDateTime,
    uint64 endDateTime,
    address currencyType,
    uint64 pickUp,
    uint64 dropOf,
    RentalityPromoService promoService,
    string memory promo,
    address user,
    uint insurance
  ) public view returns (Schemas.PaymentInfo memory, uint, uint, uint, bool) {
    bool usePromo = false;
    Schemas.CarInfo memory carInfo = addresses.carService.getCarInfoById(carId);

    uint64 daysOfTrip = getCeilDays(startDateTime, endDateTime);

     uint64 discount = uint64(promoService.getDiscountByPromo(promo, user));


 uint64 priceWithDiscount = addresses.paymentService.calculateSumWithDiscount(
      addresses.carService.ownerOf(carId),
      daysOfTrip,
      carInfo.pricePerDayInUsdCents
    );


    uint taxId = addresses.paymentService.defineTaxesType(address(addresses.carService), carId);

    (uint64 salesTaxes, uint64 govTax) = addresses.paymentService.calculateTaxes(
      taxId,
      daysOfTrip,
      priceWithDiscount + pickUp + dropOf
    );

    uint valueSum = priceWithDiscount +
      salesTaxes +
      govTax +
      carInfo.securityDepositPerTripInUsdCents +
      pickUp +
      dropOf +
      insurance;

    uint priceWithPromo = 0;
    if (discount > 0) {
      require(discount == 100 || (pickUp == 0 && pickUp == 0), 'PickUp and DropOf should be 0');
      usePromo = true;
      uint sumBeforePromo = priceWithDiscount + salesTaxes + govTax + pickUp + dropOf;
      priceWithPromo = (sumBeforePromo - ((sumBeforePromo * discount) / 100));
    }

    (uint valueSumInCurrency, int rate, uint8 decimals) = addresses.currencyConverterService.getFromUsdLatest(
      currencyType,
      valueSum
    );

    uint valueSumInCurrencyBeforePromo = valueSumInCurrency;
    uint valueSumWithPromo = valueSum;
    if (discount > 0) {
      valueSumWithPromo = priceWithPromo;

      valueSumInCurrency = addresses.currencyConverterService.getFromUsd(
        currencyType,
        priceWithPromo + carInfo.securityDepositPerTripInUsdCents + insurance,
        rate,
        decimals
      );
    }

    Schemas.PaymentInfo memory paymentInfo = Schemas.PaymentInfo(
      0,
      tx.origin,
      address(this),
      carInfo.pricePerDayInUsdCents * daysOfTrip,
      salesTaxes,
      govTax,
      priceWithDiscount,
      carInfo.securityDepositPerTripInUsdCents,
      0,
      currencyType,
      rate,
      decimals,
      0,
      0,
      pickUp,
      dropOf
    );
    if(discount == 100)
    valueSumInCurrency = 0;

    return (paymentInfo, valueSumInCurrency, valueSumInCurrencyBeforePromo, priceWithPromo, usePromo);
  }

  /// @dev Retrieves delivery data for a given car.
  /// @param carId The ID of the car for which delivery data is requested.
  /// @return deliveryData The delivery data including location details and delivery prices.
  function getDeliveryData(
    RentalityContract memory addresses,
    uint carId
  ) public view returns (Schemas.DeliveryData memory) {
    IRentalityGeoService geoService = IRentalityGeoService(addresses.carService.getGeoServiceAddress());

    Schemas.DeliveryPrices memory deliveryPrices = RentalityCarDelivery(
      addresses.adminService.getDeliveryServiceAddress()
    ).getUserDeliveryPrices(addresses.carService.ownerOf(carId));

    return
      Schemas.DeliveryData(
        geoService.getLocationInfo(addresses.carService.getCarInfoById(carId).locationHash),
        deliveryPrices.underTwentyFiveMilesInUsdCents,
        deliveryPrices.aboveTwentyFiveMilesInUsdCents,
        addresses.carService.getCarInfoById(carId).insuranceIncluded
      );
  }

  function calculateDelivery(
    RentalityContract memory addresses,
    Schemas.CreateTripRequestWithDelivery memory request
  ) public view returns (uint64, uint64) {
    bytes32 locationHash = addresses.carService.getCarInfoById(request.carId).locationHash;
    (uint64 pickUp, uint64 dropOf) = addresses.deliveryService.calculatePricesByDeliveryDataInUsdCents(
      request.pickUpInfo.locationInfo,
      request.returnInfo.locationInfo,
      IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getCarLocationLatitude(locationHash),
      IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getCarLocationLongitude(locationHash),
      addresses.carService.getCarInfoById(request.carId).createdBy
    );
    if (pickUp > 0) addresses.carService.verifySignedLocationInfo(request.pickUpInfo);
    if (dropOf > 0) addresses.carService.verifySignedLocationInfo(request.returnInfo);
    return (pickUp, dropOf);
  }

  /// @notice Retrieves detailed claim information for a specific claim ID.
  /// @dev This function fetches all relevant data for a claim including trip, car, and user information.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param claimId The ID of the claim to retrieve.
  /// @return A FullClaimInfo structure containing all relevant information about the claim.
  function getClaim(
    RentalityContract memory contracts,
    uint256 claimId
  ) public view returns (Schemas.FullClaimInfo memory) {
    RentalityClaimService claimService = contracts.claimService;
    RentalityTripService tripService = contracts.tripService;
    RentalityCarToken carService = contracts.carService;
    RentalityUserService userService = contracts.userService;
    RentalityCurrencyConverter currencyConverterService = contracts.currencyConverterService;

    Schemas.Claim memory claim = claimService.getClaim(claimId);
    Schemas.Trip memory trip = tripService.getTrip(claim.tripId);
    Schemas.CarInfo memory car = carService.getCarInfoById(trip.carId);

    string memory guestPhoneNumber = userService.getKYCInfo(trip.guest).mobilePhoneNumber;
    string memory hostPhoneNumber = userService.getKYCInfo(trip.host).mobilePhoneNumber;

    uint valueInCurrency = currencyConverterService.getFromUsd(
      trip.paymentInfo.currencyType,
      claim.amountInUsdCents,
      trip.paymentInfo.currencyRate,
      trip.paymentInfo.currencyDecimals
    );

    return
      Schemas.FullClaimInfo(
        claim,
        trip.host,
        trip.guest,
        guestPhoneNumber,
        hostPhoneNumber,
        car,
        valueInCurrency,
        IRentalityGeoService(contracts.carService.getGeoServiceAddress()).getCarTimeZoneId(car.locationHash)
      );
  }

  /// @notice Retrieves detailed information about a specific car.
  /// @dev This function fetches all relevant data for a car including geo-location and user information.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param carId The ID of the car to retrieve.
  /// @return details A CarDetails structure containing all relevant information about the car.
  function getCarDetails(
    RentalityContract memory contracts,
    uint carId,
    RentalityDimoService dimoService
  ) public view returns (Schemas.CarDetails memory details) {
    RentalityCarToken carService = contracts.carService;
    IRentalityGeoService geo = IRentalityGeoService(carService.getGeoServiceAddress());
    RentalityUserService userService = contracts.userService;

    Schemas.CarInfo memory car = carService.getCarInfoById(carId);

    details = Schemas.CarDetails(
      carId,
      userService.getKYCInfo(car.createdBy).name,
      userService.getKYCInfo(car.createdBy).profilePhoto,
      car.createdBy,
      car.brand,
      car.model,
      car.yearOfProduction,
      car.pricePerDayInUsdCents,
      car.securityDepositPerTripInUsdCents,
      car.milesIncludedPerDay,
      car.engineType,
      car.engineParams,
      geo.getCarCoordinateValidity(carId),
      car.currentlyListed,
      geo.getLocationInfo(car.locationHash),
      car.carVinNumber,
      carService.tokenURI(carId),
      dimoService.getDimoTokenId(carId)
    );
  }
  /// @notice Retrieves all cars owned by the user with information about editability.
  /// @dev This function fetches the user's cars and checks if they can be edited.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @return An array of CarInfoDTO structures containing information about the user's cars and whether they are editable.
  function getCarsOwnedByUserWithEditability(
    RentalityContract memory contracts,
    RentalityDimoService dimoService
  ) public view returns (Schemas.CarInfoDTO[] memory) {
    RentalityCarToken carService = contracts.carService;

    Schemas.CarInfo[] memory carInfoes = carService.getCarsOwnedByUser(tx.origin);

    Schemas.CarInfoDTO[] memory result = new Schemas.CarInfoDTO[](carInfoes.length);
    for (uint i = 0; i < carInfoes.length; i++) {
      result[i].carInfo = carInfoes[i];
      result[i].metadataURI = carService.tokenURI(carInfoes[i].carId);
      result[i].isEditable = isCarEditable(contracts, carInfoes[i].carId);
      result[i].dimoTokenId = dimoService.getDimoTokenId(carInfoes[i].carId);
    }

    return result;
  }

  /// @notice Checks if a car is editable based on its associated trips.
  /// @dev This function checks the status of trips associated with the car to determine if it can be edited.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param carId The ID of the car to check for editability.
  /// @return Returns true if the car is editable, otherwise false.
  function isCarEditable(RentalityContract memory contracts, uint carId) public view returns (bool) {
    RentalityTripService tripService = contracts.tripService;
    uint[] memory carTrips = tripService.getActiveTrips(carId);

    for (uint i = 0; i < carTrips.length; i++) {
      Schemas.Trip memory tripInfo = tripService.getTrip(carTrips[i]);

      if (
        tripInfo.carId == carId &&
        (tripInfo.status != Schemas.TripStatus.Finished &&
          tripInfo.status != Schemas.TripStatus.Canceled &&
          (tripInfo.status != Schemas.TripStatus.CheckedOutByHost && tripInfo.host != tripInfo.tripFinishedBy))
      ) {
        return false;
      }
    }

    return true;
  }
  function verifyClaim(
    RentalityContract memory addresses,
    Schemas.CreateClaimRequest memory request
  ) public view returns (address, address) {
    Schemas.Trip memory trip = addresses.tripService.getTrip(request.tripId);

    require(
      (trip.host == tx.origin && uint8(request.claimType) <= 7) ||
        (trip.guest == tx.origin && ((uint8(request.claimType) <= 9) && (uint8(request.claimType) >= 3))),
      'Only for trip host or guest, or wrong claim type.'
    );

    require(
      trip.status != Schemas.TripStatus.Canceled && trip.status != Schemas.TripStatus.Created,
      'Wrong trip status.'
    );
    return (trip.host, trip.guest);
  }

  function verifyConfirmCheckOut(RentalityContract memory contracts, uint tripId) public view {
    Schemas.Trip memory trip = contracts.tripService.getTrip(tripId);

    require(trip.guest == tx.origin || contracts.userService.isAdmin(tx.origin), 'For trip guest or admin');
    require(trip.host == trip.tripFinishedBy, 'No needs to confirm.');
    require(trip.status == Schemas.TripStatus.CheckedOutByHost, 'The trip is not in status CheckedOutByHost');
  }

}