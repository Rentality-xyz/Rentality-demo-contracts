// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./RentalityCarToken.sol";
import "./RentalityCurrencyConverter.sol";
import "./RentalityTripService.sol";
import "./RentalityUserService.sol";
import "./RentalityPaymentService.sol";
import "./IRentalityGateway.sol";

/// @title Rentality Platform Contract
/// @notice This contract manages various services related to the Rentality platform, including cars, trips, users, and payments.
/// @dev It allows updating service contracts, creating and managing trips, handling payments, and more.

contract RentalityPlatform is OwnableUpgradeable, UUPSUpgradeable {
    RentalityCarToken private carService;
    RentalityCurrencyConverter private currencyConverterService;
    RentalityTripService private tripService;
    RentalityUserService private userService;
    RentalityPaymentService private paymentService;


    /// @dev Modifier to restrict access to admin users only.
    modifier onlyAdmin() {
        require(
            userService.isAdmin(msg.sender) ||
            userService.isAdmin(tx.origin) ||
            (tx.origin == owner()),
            "User is not an admin"
        );
        _;
    }

    // modifier onlyHost() {
    //     require(userService.isHost(msg.sender), "User is not a host");
    //     _;
    // }

    // modifier onlyGuest() {
    //     require(userService.isGuest(msg.sender), "User is not a guest");
    //     _;
    // }

    // modifier onlyHostOrGuest() {
    //     require(
    //         userService.isHost(msg.sender) || userService.isGuest(msg.sender),
    //         "User is not a host or guest"
    //     );
    //     _;
    // }

    /// @notice Get the address of the Car service on the Rentality platform.
    /// @return The address of the Car service.
    function getCarServiceAddress() public view returns (address) {
        return address(carService);
    }

    /// @notice Update the address of the Car service on the Rentality platform.
    /// @dev This function can only be called by the platform admin.
    /// @param contractAddress The new address of the Car service.
    function updateCarService(address contractAddress) public onlyAdmin {
        carService = RentalityCarToken(contractAddress);
    }

    /// @notice Get the address of the currency converter service on the Rentality platform.
    /// @return The address of the currency converter service.
    function getCurrencyConverterServiceAddress()
    public
    view
    returns (address)
    {
        return address(currencyConverterService);
    }

    /// @notice Update the address of the currency converter service on the Rentality platform.
    /// @dev This function can only be called by the platform admin.
    /// @param contractAddress The new address of the currency converter service.
    function updateCurrencyConverterService(
        address contractAddress
    ) public onlyAdmin {
        currencyConverterService = RentalityCurrencyConverter(contractAddress);
    }

// @notice Get the address of the RentalityTripService service contract.
    function getTripServiceAddress() public view returns (address) {
        return address(tripService);
    }

    /// @notice Update the RentalityTripService service contract address.
    /// @param contractAddress The new address of the RentalityTripService contract.
    function updateTripService(address contractAddress) public onlyAdmin {
        tripService = RentalityTripService(contractAddress);
    }

    /// @notice Get the address of the RentalityUserService service contract.
    function getUserServiceAddress() public view returns (address) {
        return address(userService);
    }

    /// @notice Update the RentalityUserService service contract address.
    /// @param contractAddress The new address of the RentalityUserService contract.
    function updateUserService(address contractAddress) public onlyAdmin {
        userService = RentalityUserService(contractAddress);
    }

    /// @notice Withdraw a specific amount of funds from the contract.
    /// @param amount The amount to withdraw from the contract.
    function withdrawFromPlatform(uint256 amount) public {
        require(
            address(this).balance > 0,
            "There is no commission to withdraw"
        );
        require(
            address(this).balance >= amount,
            "There is not enough balance on the contract"
        );

        //require(payable(owner()).send(amount));
        (bool success,) = payable(owner()).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawAllFromPlatform() public {
        return withdrawFromPlatform(address(this).balance);
    }

    /// @notice Create a new trip request on the Rentality platform.
    /// @param request The details of the trip request as specified in IRentalityGateway.CreateTripRequest.
    function createTripRequest(
        IRentalityGateway.CreateTripRequest memory request
    ) public payable {
        require(msg.value > 0, "Rental fee must be greater than 0");
        require(carService.ownerOf(request.carId) != tx.origin, "Car is not available for creator");

        uint64 valueSum = request.totalDayPriceInUsdCents +
                        request.taxPriceInUsdCents +
                        request.depositInUsdCents;
        uint256 valueSumInEth = currencyConverterService.getEthFromUsd(
            valueSum,
            request.ethToCurrencyRate,
            request.ethToCurrencyDecimals
        );

        require(
            msg.value == valueSumInEth,
            "Rental fee must be equal to sum totalDayPrice + taxPrice + deposit"
        );

        if (!userService.isGuest(tx.origin)) {
            userService.grantGuestRole(tx.origin);
        }

        RentalityTripService.PaymentInfo
        memory paymentInfo = RentalityTripService.PaymentInfo(
            0,
            tx.origin,
            address(this),
            request.totalDayPriceInUsdCents,
            request.taxPriceInUsdCents,
            request.depositInUsdCents,
            0,
            RentalityTripService.CurrencyType.ETH,
            request.ethToCurrencyRate,
            request.ethToCurrencyDecimals,
            0,
            0
        );

        RentalityCarToken.CarInfo memory carInfo = carService.getCarInfoById(
            request.carId
        );

        tripService.createNewTrip(
            request.carId,
            tx.origin,
            request.host,
            carInfo.pricePerDayInUsdCents,
            request.startDateTime,
            request.endDateTime,
            request.startLocation,
            request.endLocation,
            carInfo.milesIncludedPerDay,
            request.fuelPricePerGalInUsdCents,
            paymentInfo
        );
    }
    /// @notice Approve a trip request on the Rentality platform.
    /// @param tripId The ID of the trip to approve.
    function approveTripRequest(uint256 tripId) public {
        tripService.approveTrip(tripId);

        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
        RentalityTripService.Trip[] memory intersectedTrips = tripService.getTripsForCarThatIntersect(
            trip.carId,
            trip.startDateTime,
            trip.endDateTime
        );
        if (intersectedTrips.length > 0) {
            for (uint256 i = 0; i < intersectedTrips.length; i++) {
                if (intersectedTrips[i].status == RentalityTripService.TripStatus.Created) {
                    rejectTripRequest(intersectedTrips[i].tripId);
                }
            }
        }
    }

    /// @notice Reject a trip request on the Rentality platform.
    /// @param tripId The ID of the trip to reject.
    function rejectTripRequest(uint256 tripId) public {
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);
        tripService.rejectTrip(tripId);

        uint64 valueToReturnInUsdCents = trip
            .paymentInfo
            .totalDayPriceInUsdCents +
                            trip.paymentInfo.taxPriceInUsdCents +
                            trip.paymentInfo.depositInUsdCents;

        uint64 subtractAmount;
        if (trip.status == RentalityTripService.TripStatus.Approved) {
            subtractAmount = trip.pricePerDayInUsdCents / 2;
        } else if (trip.status == RentalityTripService.TripStatus.CheckedInByHost) {
            subtractAmount = trip.pricePerDayInUsdCents;

        } else {
            subtractAmount = 0;
        }

        uint32 platformFeeInPPM = paymentService.getPlatformFeeInPPM();
        uint64 platformFee = subtractAmount * platformFeeInPPM / 1000000;
        uint64 returnToHost = subtractAmount - platformFee;

        valueToReturnInUsdCents -= subtractAmount;

        uint256 valueToReturnInEth = currencyConverterService.getEthFromUsd(
            valueToReturnInUsdCents,
            trip.paymentInfo.ethToCurrencyRate,
            trip.paymentInfo.ethToCurrencyDecimals
        );

        (bool successGuest,) = payable(trip.guest).call{value: valueToReturnInEth}("");
        require(successGuest, "Transfer to guest failed.");

        if (returnToHost > 0) {
            uint256 returnToHostInEth = currencyConverterService.getEthFromUsd(
                returnToHost,
                trip.paymentInfo.ethToCurrencyRate,
                trip.paymentInfo.ethToCurrencyDecimals
            );
            (bool successHost,) = payable(trip.host).call{value: returnToHostInEth}("");
            require(successHost, "Transfer to host failed.");
        }
    }

    /// @notice Finish a trip on the Rentality platform.
    /// @param tripId The ID of the trip to finish.
    function finishTrip(uint256 tripId) public {
        tripService.finishTrip(tripId);
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);

        uint64 valueToHostInUsdCents = trip
            .paymentInfo
            .totalDayPriceInUsdCents +
                            trip.paymentInfo.taxPriceInUsdCents +
                            trip.paymentInfo.resolveAmountInUsdCents -
                            paymentService.getPlatformFeeFrom(
                trip.paymentInfo.totalDayPriceInUsdCents +
                trip.paymentInfo.taxPriceInUsdCents
            );
        uint256 valueToHostInEth = currencyConverterService.getEthFromUsd(
            valueToHostInUsdCents,
            trip.paymentInfo.ethToCurrencyRate,
            trip.paymentInfo.ethToCurrencyDecimals
        );
        uint64 valueToGuestInUsdCents = trip.paymentInfo.depositInUsdCents -
                            trip.paymentInfo.resolveAmountInUsdCents;
        uint256 valueToGuestInEth = currencyConverterService.getEthFromUsd(
            valueToGuestInUsdCents,
            trip.paymentInfo.ethToCurrencyRate,
            trip.paymentInfo.ethToCurrencyDecimals
        );
        //require(payable(trip.host).send(valueToHostInEth));
        //require(payable(trip.guest).send(valueToGuestInEth));
        (bool successHost,) = payable(trip.host).call{value: valueToHostInEth}(
            ""
        );
        (bool successGuest,) = payable(trip.guest).call{
                value: valueToGuestInEth
            }("");
        require(successHost, "Transfer failed.");
        require(successGuest, "Transfer failed.");
    }

    /// @notice Get contact information for a specific trip on the Rentality platform.
    /// @param tripId The ID of the trip to retrieve contact information for.
    /// @return guestPhoneNumber The phone number of the guest on the trip.
    /// @return hostPhoneNumber The phone number of the host on the trip.
    function getTripContactInfo(uint256 tripId)
    public
    view
    returns (string memory guestPhoneNumber, string memory hostPhoneNumber)
    {
        RentalityTripService.Trip memory trip = tripService.getTrip(tripId);

        RentalityUserService.KYCInfo memory guestInfo = userService.getKYCInfo(
            trip.guest
        );
        RentalityUserService.KYCInfo memory hostInfo = userService.getKYCInfo(
            trip.host
        );

        return (guestInfo.mobilePhoneNumber, hostInfo.mobilePhoneNumber);
    }

    /// @notice Get KYC (Know Your Customer) information for the caller on the Rentality platform.
    /// @return kycInfo The KYC information for the caller.
    function getMyKYCInfo() external view returns (RentalityUserService.KYCInfo memory kycInfo) {
        return userService.getMyKYCInfo();
    }

    /// @notice Get chat information for trips hosted by the caller on the Rentality platform.
    /// @return chatInfo An array of chat information for trips hosted by the caller.
    function getChatInfoForHost() public view returns (IRentalityGateway.ChatInfo[] memory) {
        RentalityTripService.Trip[] memory trips = tripService.getTripsByHost(tx.origin);
        return RentalityUtils.populateChatInfo(trips, userService, carService);
    }

    /// @notice Get chat information for trips attended by the caller on the Rentality platform.
    /// @return chatInfo An array of chat information for trips attended by the caller.
    function getChatInfoForGuest() public view returns (IRentalityGateway.ChatInfo[] memory) {
        RentalityTripService.Trip[] memory trips = tripService.getTripsByGuest(tx.origin);
        return RentalityUtils.populateChatInfo(trips, userService, carService);
    }
    //   @dev Checks whether the upgrade to a new implementation is authorized.
    //  @param newImplementation The address of the new implementation contract.
    //  Requirements:
    //  - The owner must have authorized the upgrade.
    function _authorizeUpgrade(address newImplementation) internal override
    {
        _checkOwner();
    }

    /// @notice Constructor to initialize the RentalityPlatform with service contract addresses.
    /// @param carServiceAddress The address of the RentalityCarToken contract.
    /// @param currencyConverterServiceAddress The address of the RentalityCurrencyConverter contract.
    /// @param tripServiceAddress The address of the RentalityTripService contract.
    /// @param userServiceAddress The address of the RentalityUserService contract.
    /// @param paymentServiceAddress The address of the RentalityPaymentService contract.
    function initialize(
        address carServiceAddress,
        address currencyConverterServiceAddress,
        address tripServiceAddress,
        address userServiceAddress,
        address paymentServiceAddress) public initializer {

        carService = RentalityCarToken(carServiceAddress);
        currencyConverterService = RentalityCurrencyConverter(
            currencyConverterServiceAddress
        );
        tripService = RentalityTripService(tripServiceAddress);
        userService = RentalityUserService(userServiceAddress);
        paymentService = RentalityPaymentService(paymentServiceAddress);

        __Ownable_init();
    }

}