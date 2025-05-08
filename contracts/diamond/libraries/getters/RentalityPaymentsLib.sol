// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Schemas } from "../../../Schemas.sol";
import {CarTokenStorage} from '../CarTokenStorage.sol';
import {GeoServiceStorage} from '../GeoServiceStorage.sol';
import {DeliveryStorage} from '../DeliveryStorage.sol';
import {DimoServiceStorage} from '../DimoServiceStorage.sol';
import {InsuranceServiceStorage} from '../InsuranceServiceStorage.sol';
import {CurrencyConverterStorage} from '../CurrencyConverterStorage.sol';
import {UserServiceStorage} from '../UserServiceStorage.sol';
import {TaxesStorage} from '../TaxesStorage.sol';
import {TripServiceStorage} from '../TripServiceStorage.sol';
import {PaymentsStorage} from '../PaymentsStorage.sol';
import {RentalityCarTokenHelper} from './RentalityCarTokenHelper.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {RentalityTripsQueryDiamond} from './RentalityTripsQueryDiamond.sol';


library RentalityPaymentsLib {
      /// @dev Calculates the payments for a trip.
  /// @param carId The ID of the car.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param currency The currency to use for payment calculation.
  /// @param pickUpLocation lat and lon of pickUp and return locations.
  /// @param returnLocation lat and lon of pickUp and return locations.
  /// @return calculatePaymentsDTO An object containing payment details.
  function calculatePaymentsWithDelivery(
    uint carId,
    uint64 daysOfTrip,
    address currency,
    Schemas.LocationInfo memory pickUpLocation,
    Schemas.LocationInfo memory returnLocation,
    string memory promo,
    address user
  ) internal view returns (Schemas.CalculatePaymentsDTO memory) {
    Schemas.CarInfo memory car = CarTokenStorage.getCarInfoById(carId);
    uint64 deliveryFee = DeliveryStorage
      .calculatePriceByDeliveryDataInUsdCents(
        pickUpLocation,
        returnLocation,
        GeoServiceStorage.getCarLocationLatitude(
          car.locationHash
        ),
        GeoServiceStorage.getCarLocationLongitude(
          car.locationHash
        ),
        car.createdBy
      );
    return
      calculatePayments(
        carId,
        daysOfTrip,
        currency,
        deliveryFee,
        promo,
        user
      );
  }
  function calculatePayments(
    uint carId,
    uint64 daysOfTrip,
    address currency,
    uint64 deliveryFee,
    string memory promo,
    address user
  ) public view returns (Schemas.CalculatePaymentsDTO memory) {
    address carOwner = CarTokenStorage.ownerOf(carId);
    Schemas.CarInfo memory car = CarTokenStorage.getCarInfoById(carId);


    //TODO: after adding promo service
    uint64 discount = 0;
    // uint64 discount = uint64(promoService.getDiscountByPromo(promo, user));
    uint64 priceWithDiscount;
    priceWithDiscount = PaymentsStorage.calculateSumWithDiscount(
      carOwner,
      daysOfTrip,
      car.pricePerDayInUsdCents
    );

    uint64 sumWithDiscount = PaymentsStorage.calculateSumWithDiscount(
      carOwner,
      daysOfTrip,
      car.pricePerDayInUsdCents
    );

    uint taxId = TaxesStorage.defineTaxesType(carId);

    uint64 totalTaxes = TaxesStorage.calculateTaxes(
      taxId,
      daysOfTrip,
      sumWithDiscount + deliveryFee
    );

    uint64 priceBeforePromo = sumWithDiscount + totalTaxes + deliveryFee;

    uint64 discountedPrice = priceBeforePromo;
    if (discount > 0) {
      discountedPrice = priceBeforePromo - ((priceBeforePromo * discount) / 100);
    }

    uint totalPrice = car.securityDepositPerTripInUsdCents + discountedPrice;

    if (!InsuranceServiceStorage.isGuestHasInsurance(user)) {
      totalPrice += InsuranceServiceStorage.getInsurancePriceByCar(carId) * daysOfTrip;
    }

    (uint256 valueSumInCurrency, int rate, uint8 decimals) = CurrencyConverterStorage.getFromUsdLatest(
      currency,
      totalPrice
    );
    if (discount == 100) {
      valueSumInCurrency = 0;
    }

    return Schemas.CalculatePaymentsDTO(valueSumInCurrency, rate, decimals);
  }

}