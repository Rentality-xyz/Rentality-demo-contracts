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
    bytes32 cityHash = keccak256(abi.encode(geoService.getCarCity(carId)));
    bytes32 stateHash = keccak256(abi.encode(geoService.getCarState(carId)));
    bytes32 countryHash = keccak256(abi.encode(geoService.getCarCountry(carId)));

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
  /// TODO: add erc20 investment payments
  function payFinishTrip(Schemas.Trip memory trip, uint valueToHost, uint valueToGuest) public payable {
    require(userService.isManager(msg.sender), 'Only manager');
    bool successHost;
    bool successGuest;
    if (investmentService.isInvestorsCar(trip.carId)) {
      (uint hostPercents, RentalityCarInvestmentPool pool) = investmentService.getPaymentsInfo(trip.carId);
      uint depositToPool = valueToHost - ((valueToHost * hostPercents) / 100);
      valueToHost = valueToHost - depositToPool;
      pool.deposit{value: depositToPool}();
    }
    if (trip.paymentInfo.currencyType == address(0)) {
      (successHost, ) = payable(trip.host).call{value: valueToHost}('');
      (successGuest, ) = payable(trip.guest).call{value: valueToGuest}('');
    } else {
      successHost = IERC20(trip.paymentInfo.currencyType).transfer(trip.host, valueToHost);
      successGuest = IERC20(trip.paymentInfo.currencyType).transfer(trip.guest, valueToGuest);
    }
    require(successHost && successGuest, 'Transfer failed.');
  }

  function payKycCommission(uint valueInCurrency, address currencyType) public payable {
    require(userService.isManager(msg.sender), 'Only manager');
    require(!RentalityUserService(address(userService)).isCommissionPaidForUser(tx.origin), 'Commission paid');
    if (currencyType == address(0)) {
      require(msg.value == valueInCurrency, 'Not enough tokens');
    } else {
      require(IERC20(currencyType).allowance(tx.origin, address(this)) >= valueInCurrency, 'Not enough tokens');
      bool success = IERC20(currencyType).transferFrom(tx.origin, address(this), valueInCurrency);
      require(success, 'Fail to pay');
    }

    RentalityUserService(address(userService)).payCommission();
  }

  function payCreateTrip(address currencyType, uint valueSumInCurrency) public payable {
    require(userService.isManager(msg.sender), 'only manager');
    if (currencyType == address(0)) {
      require(
        msg.value == valueSumInCurrency,
        'Rental fee must be equal to sum: price with discount + taxes + deposit + delivery'
      );
    } else {
      require(
        IERC20(currencyType).allowance(tx.origin, address(this)) >= valueSumInCurrency,
        'Rental fee must be equal to sum: price with discount + taxes + deposit + delivery'
      );

      bool success = IERC20(currencyType).transferFrom(tx.origin, address(this), valueSumInCurrency);
      require(success, 'Transfer failed.');
    }
  }

  function payClaim(Schemas.Trip memory trip, uint valueToPay, uint feeInCurrency, uint commission) public payable {
    require(userService.isManager(msg.sender), 'Only manager');
    bool successHost;
    address to = tx.origin == trip.host ? trip.guest : trip.host;

    if (trip.paymentInfo.currencyType == address(0)) {
      require(msg.value >= valueToPay, 'Insufficient funds sent.');
      (successHost, ) = payable(to).call{value: valueToPay - feeInCurrency}('');

      if (msg.value > valueToPay + feeInCurrency) {
        uint256 excessValue = msg.value - valueToPay;
        (bool successRefund, ) = payable(tx.origin).call{value: excessValue}('');
        require(successRefund, 'Refund to guest failed.');
      }
    } else {
      require(IERC20(trip.paymentInfo.currencyType).allowance(tx.origin, address(this)) >= valueToPay);
      successHost = IERC20(trip.paymentInfo.currencyType).transferFrom(tx.origin, to, valueToPay - feeInCurrency);
      if (commission != 0) {
        bool successPlatform = IERC20(trip.paymentInfo.currencyType).transferFrom(tx.origin, to, feeInCurrency);
        require(successPlatform, 'Fail to transfer fee.');
      }
    }
    require(successHost, 'Transfer to host failed.');
  }

  function payRejectTrip(Schemas.Trip memory trip, uint valueToReturnInToken) public {
    bool successGuest;
    if ((trip.paymentInfo.currencyType == address(0))) {
      (successGuest, ) = payable(trip.guest).call{value: valueToReturnInToken}('');
    } else {
      successGuest = IERC20(trip.paymentInfo.currencyType).transfer(trip.guest, valueToReturnInToken);
    }
    require(successGuest, 'Transfer to guest failed.');
  }

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

  receive() external payable {}
  /// @notice Constructor to initialize the RentalityPaymentService.
  /// @param _userService The address of the RentalityUserService contract
  function initialize(
    address _userService,
    address _floridaTaxes,
    address _baseDiscount,
    address _investorService
  ) public initializer {
    userService = IRentalityAccessControl(_userService);
    investmentService = RentalityInvestment(_investorService);

    platformFeeInPPM = 200_000;

    currentDiscount = _baseDiscount;
    discountAddressToDiscountContract[_baseDiscount] = IRentalityDiscount(_baseDiscount);

    taxesId = 1;
    defaultTax = 1;
    taxesIdToTaxesContract[taxesId] = IRentalityTaxes(_floridaTaxes);

    __Ownable_init();
  }
}
