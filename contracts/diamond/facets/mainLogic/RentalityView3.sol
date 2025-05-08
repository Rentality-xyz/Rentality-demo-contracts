// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../../Schemas.sol";
import { RentalityViewLibDiamond } from "../../libraries/getters/RentalityViewLibDiamond.sol";
import { RentalityCarTokenHelper } from "../../libraries/getters/RentalityCarTokenHelper.sol";
import { RentalityTripsQueryDiamond } from "../../libraries/getters/RentalityTripsQueryDiamond.sol";
import { RentalityQueryDiamond } from "../../libraries/getters/RentalityQueryDiamond.sol";
import { CarTokenStorage } from "../../libraries/CarTokenStorage.sol";
import { InsuranceServiceStorage } from "../../libraries/InsuranceServiceStorage.sol";
import { UserServiceStorage } from "../../libraries/UserServiceStorage.sol";
import { PaymentsStorage } from "../../libraries/PaymentsStorage.sol";
import { CurrencyConverterStorage } from "../../libraries/CurrencyConverterStorage.sol";
import { GeoServiceStorage } from "../../libraries/GeoServiceStorage.sol";
import { TripServiceStorage } from "../../libraries/TripServiceStorage.sol";
import {RentalityPaymentsLib} from "../../libraries/getters/RentalityPaymentsLib.sol";

contract RentalityViewFacet3 {

      /// @notice Retrieves information about a trip by ID.
  /// @param tripId The ID of the trip.
  /// @return Trip information.
  function getTrip(uint256 tripId) public view returns (Schemas.TripDTO memory) {
    Schemas.Trip memory trip = TripServiceStorage.getTrip(tripId);
    return
      RentalityTripsQueryDiamond.getTripDTO(
        tripId,
        msg.sender,
        trip
      );
  }

  /// @notice Retrieves information about trips where the caller is the guest.
  /// @return An array of trip information.
  function getTripsAs(bool host) public view returns (Schemas.TripDTO[] memory) {
    return
      RentalityTripsQueryDiamond.getTripsAs(msg.sender, host);
  }

    function getInsurancesBy(bool host) public view returns (Schemas.InsuranceDTO[] memory) {
    return RentalityTripsQueryDiamond.getTripInsurancesBy(host, msg.sender);
  }


/// @notice Get contact information for a specific trip on the Rentality platform.
  /// @param tripId The ID of the trip to retrieve contact information for.
  /// @return guestPhoneNumber The phone number of the guest on the trip.
  /// @return hostPhoneNumber The phone number of the host on the trip.
  //// Refactoring for getTripContactInfo with RentalityContract
  function getTripContactInfo(
    uint256 tripId
  ) public view returns (string memory guestPhoneNumber, string memory hostPhoneNumber) {
    return
      RentalityTripsQueryDiamond.getTripContactInfo(tripId);
  }
}