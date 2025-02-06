// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../abstract/IRentalityAccessControl.sol';
import '../proxy/UUPSOwnable.sol';
import '../RentalityTripService.sol';
import './abstract/IRentalityDiscount.sol';
import './abstract/IRentalityTaxes.sol';
import '../investment/RentalityInvestment.sol';


/// @title Rentality Payment Service Contract
/// @notice This contract manages platform fees and allows the adjustment of the platform fee by the manager.
/// @dev It is connected to RentalityUserService to check if the caller is an admin.
contract RentalityPaymentService is UUPSOwnable {
  uint32 platformFeeInPPM;
  IRentalityAccessControl private userService;

  mapping(address => IRentalityDiscount) private discountAddressToDiscountContract;
  mapping(uint => IRentalityTaxes) private taxesIdToTaxesContract;

  address private currentDiscount;
  uint private taxesId;
  uint private defaultTax;

RentalityInvestment private investmentService;

  modifier onlyAdmin() {
    require(userService.isAdmin(tx.origin), 'Only admin.');
    _;
  }
  function getBaseDiscount() public view returns (RentalityBaseDiscount) {
    address discountAddress = address(discountAddressToDiscountContract[currentDiscount]);
    return RentalityBaseDiscount(discountAddress);
  }

  /// @notice Get the current platform fee in parts per million (PPM).
  /// @return The current platform fee in PPM.
  function getPlatformFeeInPPM() public view returns (uint32) {
    return platformFeeInPPM;
  }

  /// @notice Set the platform fee in parts per million (PPM).
  /// @param valueInPPM The new value for the platform fee in PPM.
  /// @dev Only callable by an admin. The value must be positive and not exceed 1,000,000.
  function setPlatformFeeInPPM(uint32 valueInPPM) public onlyAdmin {
    require(valueInPPM > 0, "Make sure the value isn't negative");
    require(valueInPPM <= 1_000_000, "Value can't be more than 1000000");

    platformFeeInPPM = valueInPPM;
  }

  /// @notice Get the platform fee from a given value.
  /// @param value The value from which to calculate the platform fee.
  /// @return The platform fee calculated from the given value.
  function getPlatformFeeFrom(uint256 value) public view returns (uint256) {
    return (value * platformFeeInPPM) / 1_000_000;
  }

  /// @notice Calculates the total sum with discount for a given trip duration and value.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param value The total value of the trip.
  /// @param user the address of discount provider
  /// @return The total sum with discount applied.
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) public view returns (uint64) {
    return discountAddressToDiscountContract[currentDiscount].calculateSumWithDiscount(user, daysOfTrip, value);
  }

  /// @notice Calculates the taxes for a given tax ID, trip duration, and value.
  /// @param taxId The ID of the tax.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param value The total value of the trip.
  /// @return The calculated taxes.
  function calculateTaxes(uint taxId, uint64 daysOfTrip, uint64 value) public view returns (uint64, uint64) {
    return taxesIdToTaxesContract[taxId].calculateTaxes(daysOfTrip, value);
  }

  /// @notice Defines the type of taxes based on the location of a car.
  /// @param carService The address of the car service contract.
  /// @param carId The ID of the car.
  /// @return The ID of the taxes contract corresponding to the location of the car.
  function defineTaxesType(address carService, uint carId) public view returns (uint) {
    IRentalityGeoService geoService = IRentalityGeoService(RentalityCarToken(carService).getGeoServiceAddress());
    bytes32 carLocationHash = RentalityCarToken(carService).getCarInfoById(carId).locationHash;

    bytes32 cityHash = keccak256(abi.encode(geoService.getCarCity(carLocationHash)));
    bytes32 stateHash = keccak256(abi.encode(geoService.getCarState(carLocationHash)));
    bytes32 countryHash = keccak256(abi.encode(geoService.getCarCountry(carLocationHash)));

    for (uint i = 1; i <= taxesId; i++) {
      IRentalityTaxes taxContract = taxesIdToTaxesContract[i];
      (bytes32 locationHash, Schemas.TaxesLocationType taxesLocationType) = taxContract.getLocation();

      if (taxesLocationType == Schemas.TaxesLocationType.City) {
        if (locationHash == cityHash) return i;
      }
      if (taxesLocationType == Schemas.TaxesLocationType.State) {
        if (locationHash == stateHash) return i;
      }
      if (taxesLocationType == Schemas.TaxesLocationType.Country) {
        if (locationHash == countryHash) return i;
      }
    }

    return defaultTax;
  }

  /// @notice Adds a user discount.
  /// @param data The discount data.
  function addBaseDiscount(address user, Schemas.BaseDiscount memory data) public {
    require(userService.isManager(msg.sender), 'Manager only.');
    if (!userService.isHost(user)) {
      RentalityUserService(address(userService)).grantHostRole(user);
    }
    discountAddressToDiscountContract[currentDiscount].addUserDiscount(user, abi.encode(data));
  }

  /// @notice Gets the discount for a specific user.
  /// @param userAddress The address of the user.
  /// @return The discount information for the user.
  function getBaseDiscount(address userAddress) public view returns (Schemas.BaseDiscount memory) {
    return
      abi.decode(discountAddressToDiscountContract[currentDiscount].getDiscount(userAddress), (Schemas.BaseDiscount));
  }

  /// @notice Adds a taxes contract to the system.
  /// @param taxesContactAddress The address of the taxes contract.
  function addTaxesContract(address taxesContactAddress) public onlyAdmin {
    taxesId += 1;
    taxesIdToTaxesContract[taxesId] = IRentalityTaxes(taxesContactAddress);
  }

  /// @notice Adds a discount contract to the system.
  /// @param discountContactAddress The address of the discount contract.
  function addDiscountContract(address discountContactAddress) public onlyAdmin {
    discountAddressToDiscountContract[discountContactAddress] = IRentalityDiscount(discountContactAddress);
  }

  /// @notice Changes the current discount type.
  /// @param discountContract The address of the new discount contract.
  function changeCurrentDiscountType(address discountContract) public onlyAdmin {
    require(address(discountAddressToDiscountContract[discountContract]) != address(0), 'Discount contract not found.');
    currentDiscount = discountContract;
  }

  function setDefaultTax(uint _taxId) public onlyAdmin {
    defaultTax = _taxId;
  }

  /// @notice Withdraw a specific amount of funds from the contract.
  /// @param amount The amount to withdraw from the contract.

  function withdrawFromPlatform(uint256 amount, address currencyType) public onlyAdmin {
    require(
      address(this).balance > 0 || IERC20(currencyType).balanceOf(address(this)) > 0,
      'There is no commission to withdraw'
    );

    require(
      address(this).balance >= amount || IERC20(currencyType).balanceOf(address(this)) >= amount,
      'There is not enough balance on the contract'
    );

    bool success;
    if (address(0) == currencyType) {
      //require(payable(owner()).send(amount));
      (success, ) = payable(owner()).call{value: amount}('');
      require(success, 'Transfer failed.');
    } else {
      success = IERC20(currencyType).transfer(owner(), amount);
    }
    require(success, 'Transfer failed.');
  }

  /// @notice Handles the payment and finalization of a trip, distributing funds to the host and guest.
  /// @dev This function can only be called by a manager. It handles both native currency (ETH) and ERC20 tokens.
  /// @param trip The trip data structure containing details about the trip.
  /// @param valueToHost The amount to be transferred to the host.
  /// @param valueToGuest The amount to be transferred to the guest.
   /// TODO: add erc20 investment payments
  function payFinishTrip(Schemas.Trip memory trip, uint valueToHost, uint valueToGuest, uint totalIncome) public payable {
    require(userService.isManager(msg.sender), 'Only manager');
    bool successHost;
    bool successGuest;
     (uint hostPercents, RentalityCarInvestmentPool pool) = investmentService.getPaymentsInfo(trip.carId);
    if (address(pool) != address(0)) {
      uint valueToPay = totalIncome - (totalIncome * 20 / 100);
      uint depositToPool = valueToPay - ((valueToPay * hostPercents) / 100);
      valueToHost = valueToHost - depositToPool;
      pool.deposit{value: depositToPool}(totalIncome);
    }
    if (trip.paymentInfo.currencyType == address(0)) {
      // Handle payment in native currency (ETH)
      if (valueToHost > 0) {
        (successHost, ) = payable(trip.host).call{value: valueToHost}('');
      } else {
        successHost = true;
      }
      if (valueToGuest > 0) {
        (successGuest, ) = payable(trip.guest).call{value: valueToGuest}('');
      } else {
        successGuest = true;
      }
    } else {
      // Handle payment in ERC20 tokens
      successHost = IERC20(trip.paymentInfo.currencyType).transfer(trip.host, valueToHost);
      successGuest = IERC20(trip.paymentInfo.currencyType).transfer(trip.guest, valueToGuest);
    }

    require(successHost && successGuest, 'Transfer failed.');
  }

  /// @notice Handles the payment of the KYC commission by the user.
  /// @dev This function can only be called by a manager. The function handles both native currency (ETH) and ERC20 tokens.
  /// @param valueInCurrency The amount to be paid as the KYC commission.
  /// @param currencyType The type of currency used for payment (address of the ERC20 token or address(0) for ETH).
  function payKycCommission(uint valueInCurrency, address currencyType, address user) public payable {
    require(userService.isManager(msg.sender), 'Only manager');
    require(!RentalityUserService(address(userService)).isCommissionPaidForUser(user), 'Commission paid');

    if (currencyType == address(0)) {
      _checkNativeAmount(valueInCurrency);
    } else {
      // Handle payment in ERC20 tokens
      require(IERC20(currencyType).allowance(user, address(this)) >= valueInCurrency, 'Not enough tokens');
      bool success = IERC20(currencyType).transferFrom(user, address(this), valueInCurrency);
      require(success, 'Fail to pay');
    }

    RentalityUserService(address(userService)).payCommission(user);
  }

  /// @notice Handles the payment required to create a trip.
  /// @dev This function can only be called by a manager. The function handles both native currency (ETH) and ERC20 tokens.
  /// @param currencyType The type of currency used for payment (address of the ERC20 token or address(0) for ETH).
  /// @param valueSumInCurrency The total amount to be paid, which includes price, discount, taxes, deposit, and delivery fees.
  function payCreateTrip(address currencyType, uint valueSumInCurrency, address user) public payable {
    require(userService.isManager(msg.sender), 'only manager');

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

  /// @notice Handles the payment of claims related to a trip, including transfers to the host or guest and fees.
  /// @dev This function can only be called by a manager. The function handles both native currency (ETH) and ERC20 tokens.
  /// @param trip The trip data structure containing details about the trip.
  /// @param valueToPay The amount to be paid.
  /// @param feeInCurrency The fee amount to be deducted from the payment.
  /// @param commission The commission amount to be transferred, if applicable.
  function payClaim(
    Schemas.Trip memory trip,
    uint valueToPay,
    uint feeInCurrency,
    uint commission,
    address user
  ) public payable {
    require(userService.isManager(msg.sender), 'Only manager');

    bool successHost;
    address to = user == trip.host ? trip.guest : trip.host;

    if (trip.paymentInfo.currencyType == address(0)) {
      _checkNativeAmount(valueToPay);

      (successHost, ) = payable(to).call{value: valueToPay - feeInCurrency}('');

      if (msg.value > valueToPay) {
        uint256 excessValue = msg.value - valueToPay;
        (bool successRefund, ) = payable(user).call{value: excessValue}('');
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
  function payRejectTrip(Schemas.Trip memory trip, uint valueToReturnInToken) public {
    require(userService.isManager(msg.sender), 'only Manager');
    bool successGuest;

    if (trip.paymentInfo.currencyType == address(0)) {
      // Handle refund in native currency (ETH)
      (successGuest, ) = payable(trip.guest).call{value: valueToReturnInToken}('');
    } else {
      // Handle refund in ERC20 tokens
      successGuest = IERC20(trip.paymentInfo.currencyType).transfer(trip.guest, valueToReturnInToken);
    }

    require(successGuest, 'Transfer to guest failed.');
  }

  /// @notice Checks if there are any applicable taxes for a given location based on the provided location information.
  /// @dev The function compares the hashes of the city, state, and country to the stored tax data.
  /// @param locationInfo The location information that includes city, state, and country.
  /// @return The tax ID if a matching tax exists, otherwise returns 0.
  function taxExist(Schemas.LocationInfo memory locationInfo) public view returns (uint) {
    bytes32 cityHash = keccak256(abi.encode(locationInfo.city));
    bytes32 stateHash = keccak256(abi.encode(locationInfo.state));
    bytes32 countryHash = keccak256(abi.encode(locationInfo.country));

    for (uint i = 1; i <= taxesId; i++) {
      IRentalityTaxes taxContract = taxesIdToTaxesContract[i];
      (bytes32 locationHash, Schemas.TaxesLocationType taxesLocationType) = taxContract.getLocation();

      if (taxesLocationType == Schemas.TaxesLocationType.City) {
        if (locationHash == cityHash) return i;
      }
      if (taxesLocationType == Schemas.TaxesLocationType.State) {
        if (locationHash == stateHash) return i;
      }
      if (taxesLocationType == Schemas.TaxesLocationType.Country) {
        if (locationHash == countryHash) return i;
      }
    }

    return 0;
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

  receive() external payable {}
  /// @notice Constructor to initialize the RentalityPaymentService.
  /// @param _userService The address of the RentalityUserService contract
  function initialize(address _userService, address _floridaTaxes, address _baseDiscount,address _investorService) public initializer {
    userService = IRentalityAccessControl(_userService);
    platformFeeInPPM = 200_000;

    currentDiscount = _baseDiscount;
    discountAddressToDiscountContract[_baseDiscount] = IRentalityDiscount(_baseDiscount);

    taxesId = 1;
    defaultTax = 1;
    taxesIdToTaxesContract[taxesId] = IRentalityTaxes(_floridaTaxes);

  investmentService = RentalityInvestment(_investorService);
    __Ownable_init();
  }
}
