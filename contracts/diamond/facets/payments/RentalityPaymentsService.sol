// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Schemas} from "../../../Schemas.sol";
import { PaymentsStorage } from "../../libraries/PaymentsStorage.sol";
import { UserServiceStorage } from "../../libraries/UserServiceStorage.sol";
import { CurrencyConverterStorage } from "../../libraries/CurrencyConverterStorage.sol";
import {RentalityBaseDiscount} from "../../../payments/RentalityBaseDiscount.sol";
import '../../../payments/abstract/IRentalityDiscount.sol';
import {RentalityInvestment} from "../../../investment/RentalityInvestment.sol";

contract RentalityPaymentsServiceFacet {


  /// @notice Adds a user discount.
  /// @param data The discount data.
  function addBaseDiscount(Schemas.BaseDiscount memory data) public {
    address user = msg.sender;
    PaymentsStorage.PaymentsFaucetStorage storage s = PaymentsStorage.accessStorage();
    if (!UserServiceStorage.isHost(user)) {
      UserServiceStorage.grantHostRole(user);
    }
    s.discountAddressToDiscountContract[s.currentDiscount].addUserDiscount(msg.sender, abi.encode(data));
  }
 function payKycCommission(address currency) public payable {
    (uint valueToPay, , ) = CurrencyConverterStorage.getFromUsdLatest(
      currency,
      UserServiceStorage.getKycCommission()
    );

    PaymentsStorage.payKycCommission(valueToPay, currency, msg.sender);
  }

  function getPlatformFeeFrom(uint256 value) public view returns (uint256) {
    return PaymentsStorage.getPlatformFeeFrom(value);
  }
   /// @notice Calculates the total sum with discount for a given trip duration and value.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param value The total value of the trip.
  /// @param user the address of discount provider
  /// @return The total sum with discount applied.
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
    PaymentsStorage.PaymentsFaucetStorage storage s = PaymentsStorage.accessStorage();
    return s.discountAddressToDiscountContract[s.currentDiscount].calculateSumWithDiscount(user, daysOfTrip, value);
  }

  
}