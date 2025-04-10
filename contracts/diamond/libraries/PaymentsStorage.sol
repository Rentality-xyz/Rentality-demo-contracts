// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import '../../payments/abstract/IRentalityDiscount.sol';
import{Schemas} from "../../Schemas.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {RentalityInvestment} from "../../investment/RentalityInvestment.sol";
import {RentalityCarInvestmentPool} from "../../investment/RentalityInvestmentPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UserServiceStorage} from "./UserServiceStorage.sol";
import {RentalityBaseDiscount} from "../../payments/RentalityBaseDiscount.sol";
import "hardhat/console.sol";


library PaymentsStorage {
  event Data (address indexed host, address indexed guest, uint indexed sum,uint sumGuest, uint balance, bool guestT, bool hostT); 

    struct PaymentsFaucetStorage {
        uint32 platformFeeInPPM;

        mapping(address => IRentalityDiscount) discountAddressToDiscountContract;

        address currentDiscount;
        RentalityInvestment investmentService;
    }

    function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) internal view returns (uint64) {
    PaymentsFaucetStorage storage s = accessStorage();
    return s.discountAddressToDiscountContract[s.currentDiscount].calculateSumWithDiscount(user, daysOfTrip, value);
  }
  function getPlatformFeeFrom(uint256 value) internal view returns (uint256) {
    PaymentsFaucetStorage storage s = accessStorage();
    return (value * s.platformFeeInPPM) / 1_000_000;
  }
  function payCreateTrip(address currencyType, uint valueSumInCurrency, address user, uint carId) internal  {
        PaymentsFaucetStorage storage s = accessStorage();
    // (, RentalityCarInvestmentPool pool, address currency) =  s.investmentService.getPaymentsInfo(carId);
    // if (address(pool) != address(0)) require(currency == currencyType, 'wrong currency type');

    if (currencyType == address(0)) {
      // Handle payment in native currency (ETH)
      _checkNativeAmount(valueSumInCurrency);
    } else {
      // Handle payment in ERC20 tokens
      require(
        IERC20(currencyType).allowance(user, address(this)) >= valueSumInCurrency,
        'Rental fee must be equal to sum: price with discount + taxes + deposit + delivery'
      );

      bool success = IERC20(currencyType).transferFrom(user, address(this), valueSumInCurrency);
      require(success, 'Transfer failed.');
    }
  }

  function payFinishTrip(
    Schemas.Trip memory trip,
    uint valueToHost,
    uint valueToGuest,
    uint totalIncome
  ) internal  {
    PaymentsFaucetStorage storage s = accessStorage();
    bool successHost;
    bool successGuest;
    // (uint hostPercents, RentalityCarInvestmentPool pool, address currency) = s.investmentService.getPaymentsInfo(
    //   trip.carId
    // );
    // if (address(pool) != address(0)) {
    //   uint valueToPay = totalIncome - ((totalIncome * 20) / 100);
    //   uint depositToPool = valueToPay - ((valueToPay * hostPercents) / 100);
    //   valueToHost = valueToHost - depositToPool;
    //   if (currency == address(0)) pool.deposit{value: depositToPool}(totalIncome, depositToPool);
    //   else {
    //     bool success = IERC20(currency).transfer(address(pool), depositToPool);
    //     require(success, 'fail to deposit to pool');
    //     pool.deposit(totalIncome, depositToPool);
    //   }
    // }

    if (trip.paymentInfo.currencyType == address(0)) {
      // Handle payment in native currency (ETH)
      if (valueToHost > 0) {
        (successHost, ) = (trip.host).call{value: valueToHost}('');
  
      } else {
        successHost = true;
      }
      if (valueToGuest > 0) {
        (successGuest, ) = (trip.guest).call{value: valueToGuest}('');
      } else {
        successGuest = true;
      }
    } 
    
    else {
      // Handle payment in ERC20 tokens
      successHost = IERC20(trip.paymentInfo.currencyType).transfer(trip.host, valueToHost);
      successGuest = IERC20(trip.paymentInfo.currencyType).transfer(trip.guest, valueToGuest);
    }
   privateEmit(trip,valueToHost, valueToGuest,successHost, successGuest);

    require(successHost && successGuest, 'Transfer failed.');
  }
  function privateEmit(Schemas.Trip memory trip, uint valueToHost, uint valueToGuest, bool host, bool guest) private {
     console.log("trip.host:", trip.host);
        console.log("trip.guest:", trip.guest);
        console.log("value.host:", valueToHost);
        console.log("value.guest:", valueToGuest);
        console.log("balance:", address(this).balance);
         console.log("address this :", address(this));
        console.log("host:", host);
        console.log("guest:", guest);

  }

  /// @notice Handles the payment of the KYC commission by the user.
  /// @dev This function can only be called by a manager. The function handles both native currency (ETH) and ERC20 tokens.
  /// @param valueInCurrency The amount to be paid as the KYC commission.
  /// @param currencyType The type of currency used for payment (address of the ERC20 token or address(0) for ETH).
  function payKycCommission(uint valueInCurrency, address currencyType, address user) internal {
    require(!UserServiceStorage.isCommissionPaidForUser(user), 'Commission paid');

    if (currencyType == address(0)) {
      _checkNativeAmount(valueInCurrency);
    } else {
      // Handle payment in ERC20 tokens
      require(IERC20(currencyType).allowance(user, address(this)) >= valueInCurrency, 'Not enough tokens');
      bool success = IERC20(currencyType).transferFrom(user, address(this), valueInCurrency);
      require(success, 'Fail to pay');
    }

    UserServiceStorage.payCommission(user);
  }

  function payClaim(
    Schemas.Trip memory trip,
    uint valueToPay,
    uint feeInCurrency,
    uint commission,
    address user
  ) internal  {

    bool successHost;
    address to = user == trip.host ? trip.guest : trip.host;

    if (trip.paymentInfo.currencyType == address(0)) {
      _checkNativeAmount(valueToPay);

      (successHost, ) = (to).call{value: valueToPay - feeInCurrency}('');

      if (msg.value > valueToPay) {
        uint256 excessValue = msg.value - valueToPay;
        (bool successRefund, ) = (user).call{value: excessValue}('');
        require(successRefund, 'Refund to guest failed.');
      }
    } else {
      // Handle payment in ERC20 tokens
      require(IERC20(trip.paymentInfo.currencyType).allowance(user, address(this)) >= valueToPay);
      successHost = IERC20(trip.paymentInfo.currencyType).transferFrom(user, to, valueToPay - feeInCurrency);
      if (commission != 0) {
        bool successPlatform = IERC20(trip.paymentInfo.currencyType).transferFrom(user, to, feeInCurrency);
        require(successPlatform, 'Fail to transfer fee.');
      }
    }

    require(successHost, 'Transfer to host failed.');
  }

  /// @notice Handles the refund process when a trip is rejected, returning the appropriate amount to the guest.
  /// @dev This function handles both native currency (ETH) and ERC20 tokens.
  /// @param trip The trip data structure containing details about the trip.
  /// @param valueToReturnInToken The amount to be returned to the guest.
  function payRejectTrip(Schemas.Trip memory trip, uint valueToReturnInToken) internal {
    bool successGuest;
    console.log("GUEST REJECT PAY:", valueToReturnInToken);

    if (trip.paymentInfo.currencyType == address(0)) {
      // Handle refund in native currency (ETH)
      (successGuest, ) = (trip.guest).call{value: valueToReturnInToken}('');
    } else {
      // Handle refund in ERC20 tokens
      successGuest = IERC20(trip.paymentInfo.currencyType).transfer(trip.guest, valueToReturnInToken);
    }

    require(successGuest, 'Transfer to guest failed.');
  }

 
  function _checkNativeAmount(uint value) internal view {
    uint diff = 0;
    if (msg.value > value) {
      diff = msg.value - value;
    } else {
      diff = value - msg.value;
    }
    require(diff <= value / 100, 'Not enough tokens');
  }


 function getBaseDiscount() internal view returns (RentalityBaseDiscount) {
    PaymentsFaucetStorage storage s = accessStorage();
    address discountAddress = address(s.discountAddressToDiscountContract[s.currentDiscount]);
    return RentalityBaseDiscount(discountAddress);
  }
  

     function accessStorage() internal pure returns (PaymentsFaucetStorage storage ds) {
        bytes32 position = LibDiamond.PAYMENTS_STORAGE_POSITION;
        assembly { ds.slot := position }
    }
    
}