/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './RentalityCarToken.sol';
import './payments/RentalityCurrencyConverter.sol';
import './RentalityTripService.sol';
import './RentalityUserService.sol';

import './Schemas.sol';
import './payments/RentalityPaymentService.sol';
import './proxy/UUPSOwnable.sol';
import './features/RentalityClaimService.sol';
import './RentalityAdminGateway.sol';

/// @title Rentality Platform Contract
/// @notice This contract manages various services related to the Rentality platform, including cars, trips, users, and payments.
/// @dev It allows updating service contracts, creating and managing trips, handling payments, and more.
/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityUtils doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityPlatform is UUPSOwnable {
    RentalityCarToken private carService;
    RentalityCurrencyConverter private currencyConverterService;
    RentalityTripService private tripService;
    RentalityUserService private userService;
    RentalityPaymentService private paymentService;
    RentalityClaimService private claimService;

    // unused, have to be here, because of proxy
    address private automationService;

    /// @dev Modifier to restrict access to admin users only.
    modifier onlyAdmin() {
        require(
            userService.isAdmin(msg.sender) || userService.isAdmin(tx.origin) || (tx.origin == owner()),
            'User is not an admin'
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

    function updateServiceAddresses(RentalityAdminGateway adminService) public {
        carService = RentalityCarToken(adminService.getCarServiceAddress());
        currencyConverterService = RentalityCurrencyConverter(adminService.getCurrencyConverterServiceAddress());
        tripService = RentalityTripService(adminService.getTripServiceAddress());
        userService = RentalityUserService(adminService.getTripServiceAddress());
        paymentService = RentalityPaymentService(adminService.getPaymentService());
        claimService = RentalityClaimService(adminService.getClaimServiceAddress());
    }

    /// @notice Withdraw a specific amount of funds from the contract.
    /// @param amount The amount to withdraw from the contract.
    function withdrawFromPlatform(uint256 amount, address currencyType) public {
        require(
            address(this).balance > 0 || IERC20(currencyType).balanceOf(address(this)) > 0,
            'There is no commission to withdraw'
        );

        require(
            address(this).balance >= amount || IERC20(currencyType).balanceOf(address(this)) >= amount,
            'There is not enough balance on the contract'
        );

        bool success;
        if (currencyConverterService.isETH(currencyType)) {
            //require(payable(owner()).send(amount));
            (success,) = payable(owner()).call{value: amount}('');
            require(success, 'Transfer failed.');
        } else {
            success = IERC20(currencyType).transfer(owner(), amount);
        }
        require(success, 'Transfer failed.');
    }

    function withdrawAllFromPlatform(address currencyType) public {
        return withdrawFromPlatform(address(this).balance, currencyType);
    }

    /// @notice Create a new trip request on the Rentality platform.
    /// @param request The details of the trip request as specified in IRentalityGateway.CreateTripRequest.
    function createTripRequest(Schemas.CreateTripRequest memory request) public payable {
        require(userService.hasPassedKYCAndTC(tx.origin), 'KYC or TC not passed.');
        require(currencyConverterService.currencyTypeIsAvailable(request.currencyType), 'Token is not available.');
        require(carService.ownerOf(request.carId) != tx.origin, 'Car is not available for creator');
        require(
            !isCarUnavailable(request.carId, request.startDateTime, request.endDateTime),
            'Unavailable for current date.'
        );

        uint64 daysOfTrip = RentalityUtils.getCeilDays(request.startDateTime, request.endDateTime);
        Schemas.CarInfo memory carInfo = carService.getCarInfoById(request.carId);

        uint64 priceWithDiscount = paymentService.calculateSumWithDiscount(
            carService.ownerOf(request.carId),
            daysOfTrip,
            carInfo.pricePerDayInUsdCents * 10_000
        );
        uint taxId = paymentService.defineTaxesType(address(carService), request.carId);
        require(taxId != 0, 'Taxes contract not found.');

        uint64 taxes = paymentService.calculateTaxes(taxId, daysOfTrip, priceWithDiscount);

        uint valueSum = priceWithDiscount + taxes + (carInfo.securityDepositPerTripInUsdCents * 10_000);

        (int rate, uint8 decimals) = currencyConverterService.getCurrentRate(
            request.currencyType
        );
        uint valueSumInCurrency = currencyConverterService.getFromUsd(
            request.currencyType,
            valueSum,
            rate,
            decimals
        );
        if (currencyConverterService.isETH(request.currencyType)) {
            require(
                msg.value == valueSumInCurrency / 10_000,
                'Rental fee must be equal to sum: price with discount + taxes + deposit'
            );
        } else {
            require(
                IERC20(request.currencyType).allowance(tx.origin, address(this)) >= valueSumInCurrency,
                'Rental fee must be equal to sum: price with discount + taxes + deposit'
            );

            bool success = IERC20(request.currencyType).transferFrom(tx.origin, address(this), valueSumInCurrency);
            require(success, 'Transfer failed.');
        }
        /// updating cache currency data
        currencyConverterService.getCurrencyRateWithCache(request.currencyType);

        if (!userService.isGuest(tx.origin)) {
            userService.grantGuestRole(tx.origin);
        }

        Schemas.PaymentInfo memory paymentInfo = Schemas.PaymentInfo(
            0,
            tx.origin,
            address(this),
            carInfo.pricePerDayInUsdCents,
            taxes,
            priceWithDiscount,
            carInfo.securityDepositPerTripInUsdCents,
            0,
            request.currencyType,
            rate,
            decimals,
            0,
            0
        );

        tripService.createNewTrip(
            request.carId,
            tx.origin,
            carService.ownerOf(request.carId),
            carInfo.pricePerDayInUsdCents,
            request.startDateTime,
            request.endDateTime,
            IRentalityGeoService(
                carService.
                getGeoServiceAddress()).
            getCarCity(
                request.carId
            ),
            IRentalityGeoService(
                carService.getGeoServiceAddress()).
            getCarCity(
                request.carId
            ),
            carInfo.milesIncludedPerDay,
            paymentInfo
        );
    }

    // @dev Checks if a car has any active trips within the specified time range.
    // @param carId The ID of the car to check for availability.
    // @param startDateTime The start time of the time range.
    // @param endDateTime The end time of the time range.
    // @return A boolean indicating whether the car is unavailable during the specified time range.
    function isCarUnavailable(uint256 carId, uint64 startDateTime, uint64 endDateTime) private view returns (bool) {
        // Iterate through all trips to check for intersections with the specified car and time range.
        for (uint256 tripId = 1; tripId <= tripService.totalTripCount(); tripId++) {
            Schemas.Trip memory trip = tripService.getTrip(tripId);
            Schemas.CarInfo memory car = carService.getCarInfoById(trip.carId);

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

    /// @notice Approve a trip request on the Rentality platform.
    /// @param tripId The ID of the trip to approve.
    function approveTripRequest(uint256 tripId) public {
        tripService.approveTrip(tripId);

        Schemas.Trip memory trip = tripService.getTrip(tripId);
        Schemas.Trip[] memory intersectedTrips = RentalityQuery.getTripsForCarThatIntersect(
            address(tripService),
            address(carService),
            trip.carId,
            trip.startDateTime,
            trip.endDateTime
        );
        if (intersectedTrips.length > 0) {
            for (uint256 i = 0; i < intersectedTrips.length; i++) {
                if (intersectedTrips[i].status == Schemas.TripStatus.Created) {
                    rejectTripRequest(intersectedTrips[i].tripId);
                }
            }
        }
    }
    /// @notice Reject a trip request on the Rentality platform.
    /// @param tripId The ID of the trip to reject.
    function rejectTripRequest(uint256 tripId) public {
        Schemas.Trip memory trip = tripService.getTrip(tripId);
        Schemas.TripStatus statusBeforeCancellation = trip.status;

        tripService.rejectTrip(tripId);

        uint64 valueToReturnInUsdCents = trip.paymentInfo.priceWithDiscount +
                            trip.paymentInfo.taxPriceInUsdCents +
                            trip.paymentInfo.depositInUsdCents;

        uint256 valueToReturnInToken = currencyConverterService.getFromUsd(
            trip.paymentInfo.currencyType,
            valueToReturnInUsdCents,
            trip.paymentInfo.currencyRate,
            trip.paymentInfo.currencyDecimals
        );
        bool successGuest;
        if (currencyConverterService.isETH(trip.paymentInfo.currencyType)) {
            (successGuest,) = payable(trip.guest).call{value: valueToReturnInToken}('');
        } else {
            successGuest = IERC20(trip.paymentInfo.currencyType).transfer(trip.guest, valueToReturnInToken);
        }
        require(successGuest, 'Transfer to guest failed.');

        tripService.saveTransactionInfo(tripId, 0, statusBeforeCancellation, valueToReturnInUsdCents, 0);
    }

    /// @notice Confirms the check-out for a trip.
    /// @param tripId The ID of the trip to be confirmed.
    function confirmCheckOut(uint256 tripId) public {
        Schemas.Trip memory trip = tripService.getTrip(tripId);

        require(trip.guest == tx.origin || userService.isAdmin(tx.origin), 'For trip guest or admin only');
        require(trip.host == trip.tripFinishedBy, 'No needs to confirm.');
        require(trip.status == Schemas.TripStatus.CheckedOutByGuest, 'The trip is not in status CheckedOutByGuest');
        _finishTrip(tripId);
    }

    /// @notice Finish a trip on the Rentality platform.
    /// @param tripId The ID of the trip to finish.
    function finishTrip(uint256 tripId) public {
        Schemas.Trip memory trip = tripService.getTrip(tripId);
        require(trip.status == Schemas.TripStatus.CheckedOutByHost, 'The trip is not in status CheckedOutByHost');
        _finishTrip(tripId);
    }

    /// @notice Finish a trip on the Rentality platform.
    /// @param tripId The ID of the trip to finish.
    function _finishTrip(uint256 tripId) internal {
        tripService.finishTrip(tripId);
        Schemas.Trip memory trip = tripService.getTrip(tripId);

        uint rentalityFeeInUSDCents = currencyConverterService.getFromUsd(
            trip.paymentInfo.currencyType,
            trip.paymentInfo.priceWithDiscount,
            trip.paymentInfo.currencyRate,
            trip.paymentInfo.currencyDecimals
        );

        uint rentalityFee = paymentService.getPlatformFeeFrom(
        // For accuracy
            currencyConverterService.getFromUsd(
                trip.paymentInfo.currencyType,
                trip.paymentInfo.priceWithDiscount,
                trip.paymentInfo.currencyRate,
                trip.paymentInfo.currencyDecimals
            ));

        uint256 valueToHostInUsdCents = trip.paymentInfo.priceWithDiscount +
                            trip.paymentInfo.taxPriceInUsdCents +
                            trip.paymentInfo.resolveAmountInUsdCents;

        uint256 valueToGuestInUsdCents = trip.paymentInfo.depositInUsdCents - trip.paymentInfo.resolveAmountInUsdCents;

        uint256 valueToHost = currencyConverterService.getFromUsd(
            trip.paymentInfo.currencyType,
            valueToHostInUsdCents,
            trip.paymentInfo.currencyRate,
            trip.paymentInfo.currencyDecimals
        ) - rentalityFee;

        uint256 valueToGuest = currencyConverterService.getFromUsd(
            trip.paymentInfo.currencyType,
            valueToGuestInUsdCents,
            trip.paymentInfo.currencyRate,
            trip.paymentInfo.currencyDecimals
        );
        bool successHost;
        bool successGuest;
        if (currencyConverterService.isETH(trip.paymentInfo.currencyType)) {
            (successHost,) = payable(trip.host).call{value: valueToHost}('');
            (successGuest,) = payable(trip.guest).call{value: valueToGuest}('');
        } else {
            successHost = IERC20(trip.paymentInfo.currencyType).transfer(trip.host, valueToHost);
            successGuest = IERC20(trip.paymentInfo.currencyType).transfer(trip.guest, valueToGuest);
        }
        require(successHost && successGuest, 'Transfer failed.');

        tripService.saveTransactionInfo(
            tripId,
            rentalityFeeInUSDCents,
            Schemas.TripStatus.Finished,
            valueToGuestInUsdCents,
            valueToHostInUsdCents - rentalityFeeInUSDCents
        );
    }

    /// @notice Creates a new claim for a specific trip.
    /// @dev Only the host of the trip can create a claim, and certain trip status checks are performed.
    /// @param request Details of the claim to be created.
    function createClaim(Schemas.CreateClaimRequest memory request) public {
        Schemas.Trip memory trip = tripService.getTrip(request.tripId);

        require(trip.host == tx.origin, 'Only for trip host.');
        require(
            trip.status != Schemas.TripStatus.Canceled && trip.status != Schemas.TripStatus.Created,
            'Wrong trip status.'
        );

        claimService.createClaim(request, trip.host, trip.guest);
    }

    /// @notice Rejects a specific claim.
    /// @dev Only the host or guest of the associated trip can reject the claim.
    /// @param claimId ID of the claim to be rejected.
    function rejectClaim(uint256 claimId) public {
        Schemas.Claim memory claim = claimService.getClaim(claimId);
        Schemas.Trip memory trip = tripService.getTrip(claim.tripId);

        require(trip.host == tx.origin || trip.guest == tx.origin, 'Only for trip guest or host.');

        claimService.rejectClaim(claimId, tx.origin, trip.host, trip.guest);
    }

    /// @notice Pays a specific claim, transferring funds to the host and, if applicable, refunding excess to the guest.
    /// @dev Only the guest of the associated trip can pay the claim, and certain checks are performed.
    /// @param claimId ID of the claim to be paid.
    function payClaim(uint256 claimId) public payable {
        Schemas.Claim memory claim = claimService.getClaim(claimId);
        Schemas.Trip memory trip = tripService.getTrip(claim.tripId);

        require(trip.guest == tx.origin, 'Only guest.');
        require(
            claim.status != Schemas.ClaimStatus.Paid && claim.status != Schemas.ClaimStatus.Cancel,
            'Wrong claim Status.'
        );

        uint256 valueToPay = currencyConverterService.getFromUsd(
            trip.paymentInfo.currencyType,
            claim.amountInUsdCents,
            trip.paymentInfo.currencyRate,
            trip.paymentInfo.currencyDecimals
        );
        claimService.payClaim(claimId, trip.host, trip.guest);
        bool successHost;

        if (currencyConverterService.isETH(trip.paymentInfo.currencyType)) {
            require(msg.value >= valueToPay, 'Insufficient funds sent.');
            (successHost,) = payable(trip.host).call{value: valueToPay}('');

            if (msg.value > valueToPay) {
                uint256 excessValue = msg.value - valueToPay;
                (bool successRefund,) = payable(tx.origin).call{value: excessValue}('');
                require(successRefund, 'Refund to guest failed.');
            }
        } else {
            require(IERC20(trip.paymentInfo.currencyType).allowance(tx.origin, address(this)) >= valueToPay);
            successHost = IERC20(trip.paymentInfo.currencyType).transferFrom(tx.origin, trip.host, valueToPay);
        }
        require(successHost, 'Transfer to host failed.');
    }

    /// @notice Updates the status of a specific claim based on the current timestamp.
    /// @dev This function is typically called periodically to check and update claim status.
    /// @param claimId ID of the claim to be updated.
    function updateClaim(uint256 claimId) public {
        Schemas.Claim memory claim = claimService.getClaim(claimId);
        Schemas.Trip memory trip = tripService.getTrip(claim.tripId);

        claimService.updateClaim(claimId, trip.host, trip.guest);
    }

    /// @notice Gets detailed information about a specific claim.
    /// @dev Returns a structure containing information about the claim, associated trip, and car details.
    /// @param claimId ID of the claim.
    /// @return Full information about the claim.
    function getClaim(uint256 claimId) public view returns (Schemas.FullClaimInfo memory) {
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

        return Schemas.FullClaimInfo(claim, trip.host, trip.guest, guestPhoneNumber, hostPhoneNumber, car, valueInCurrency);
    }

    /// @notice Get contact information for a specific trip on the Rentality platform.
    /// @param tripId The ID of the trip to retrieve contact information for.
    /// @return guestPhoneNumber The phone number of the guest on the trip.
    /// @return hostPhoneNumber The phone number of the host on the trip.
    function getTripContactInfo(
        uint256 tripId
    ) public view returns (string memory guestPhoneNumber, string memory hostPhoneNumber) {
        require(userService.isHostOrGuest(tx.origin), 'User is not a host or guest');
        Schemas.Trip memory trip = tripService.getTrip(tripId);

        Schemas.KYCInfo memory guestInfo = userService.getKYCInfo(trip.guest);
        Schemas.KYCInfo memory hostInfo = userService.getKYCInfo(trip.host);

        return (guestInfo.mobilePhoneNumber, hostInfo.mobilePhoneNumber);
    }

    /// @notice Get KYC (Know Your Customer) information for the caller on the Rentality platform.
    /// @return kycInfo The KYC information for the caller.
    function getMyKYCInfo() external view returns (Schemas.KYCInfo memory kycInfo) {
        return userService.getMyKYCInfo();
    }
//
//    /// @notice Get chat information for trips hosted by the caller on the Rentality platform.
//    /// @return chatInfo An array of chat information for trips hosted by the caller.
//    function getChatInfoForHost() public view returns (Schemas.ChatInfo[] memory) {
//        Schemas.TripDTO[] memory trips = RentalityQuery.getTripsByHost(
//            address(tripService),
//            address(userService),
//            address(carService),
//            tx.origin
//        );
//        return RentalityUtils.populateChatInfo(trips, address(userService), address(carService));
//    }

    /// @notice Get chat information for trips attended by the caller on the Rentality platform.
    /// @return chatInfo An array of chat information for trips attended by the caller.
//    function getChatInfoForGuest() public view returns (Schemas.ChatInfo[] memory) {
//        Schemas.TripDTO[] memory trips = RentalityQuery.getTripsByGuest(
//            address(tripService),
//            address(userService),
//            address(carService),
//            tx.origin
//        );
//        return RentalityUtils.populateChatInfo(trips, address(userService), address(carService));
//    }

    /// @dev Calculates the payments for a trip.
    /// @param carId The ID of the car.
    /// @param daysOfTrip The duration of the trip in days.
    /// @param currency The currency to use for payment calculation.
    /// @return calculatePaymentsDTO An object containing payment details.
    function calculatePayments(
        uint carId,
        uint64 daysOfTrip,
        address currency
    ) public view returns (Schemas.CalculatePaymentsDTO memory) {
        address carOwner = carService.ownerOf(carId);
        Schemas.CarInfo memory car = carService.getCarInfoById(carId);

        uint64 sumWithDiscount = paymentService.calculateSumWithDiscount(carOwner, daysOfTrip, car.pricePerDayInUsdCents);
        uint taxId = paymentService.defineTaxesType(address(carService), carId);

        uint64 taxes = paymentService.calculateTaxes(taxId, daysOfTrip, sumWithDiscount);
        (int rate, uint8 decimals) = currencyConverterService.getCurrentRate(currency);

        uint256 valueSumInCurrency = currencyConverterService.getFromUsd(
            currency,
            car.securityDepositPerTripInUsdCents + taxes + sumWithDiscount,
            rate,
            decimals
        );

        return Schemas.CalculatePaymentsDTO(valueSumInCurrency, rate, decimals);
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
        address paymentServiceAddress,
        address claimServiceAddress
    ) public initializer {
        carService = RentalityCarToken(carServiceAddress);
        currencyConverterService = RentalityCurrencyConverter(currencyConverterServiceAddress);
        tripService = RentalityTripService(tripServiceAddress);
        userService = RentalityUserService(userServiceAddress);
        paymentService = RentalityPaymentService(paymentServiceAddress);
        claimService = RentalityClaimService(claimServiceAddress);

        __Ownable_init();
    }
}
