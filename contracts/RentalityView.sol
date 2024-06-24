import "./Schemas.sol";
import "./RentalityGateway.sol";
import "./RentalityAdminGateway.sol";
import "./RentalityPlatform.sol";
import "./RentalityTripService.sol";
import "./RentalityUserService.sol";
import "./RentalityCarToken.sol";
import "./features/RentalityClaimService.sol";
import "./payments/RentalityPaymentService.sol";
import "./payments/RentalityCurrencyConverter.sol";
import "./libs/RentalityUtils.sol";
import "./libs/RentalityQuery.sol";
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import "./libs/RentalityTripsQuery.sol";
    error FunctionNotFound();
/// @dev SAFETY: The linked library is not supported yet because it can modify the state or call
///  selfdestruct, as far as RentalityUtils doesn't has this logic,
/// it's completely safe for upgrade
/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract RentalityView is UUPSUpgradeable, Initializable {
    RentalityContract public addresses;
    using RentalityQuery for RentalityContract;
    using RentalityUtils for RentalityContract;
    using RentalityTripsQuery for RentalityContract;

    fallback(bytes calldata) external returns (bytes memory) {
        revert FunctionNotFound();
    }

    function updateServiceAddresses(RentalityAdminGateway adminService) public {
        require(addresses.userService.isAdmin(tx.origin), 'only Admin.');
        addresses = adminService.getRentalityContracts();
    }

/// @notice Retrieves information about a car by its ID.
/// @param carId The ID of the car.
/// @return Car information as a struct.
    function getCarInfoById(uint256 carId) public view returns (Schemas.CarInfo memory) {
        return addresses.carService.getCarInfoById(carId);
    }

/// @notice Retrieves the metadata URI of a car by its ID.
/// @param carId The ID of the car.
/// @return The metadata URI of the car.
    function getCarMetadataURI(uint256 carId) public view returns (string memory) {
        return addresses.carService.tokenURI(carId);
    }
// function updateCarInfo(
//     RentalityCarToken.UpdateCarInfoRequest memory request
// ) public onlyHost {
//     return
//         carService.updateCarInfo(
//             request.carId,
//             request.pricePerDayInUsdCents,
//             request.securityDepositPerTripInUsdCents,
//             request.fuelPricePerGalInUsdCents,
//             request.milesIncludedPerDay,
//             request.country,
//             request.state,
//             request.city,
//             request.locationLatitudeInPPM,
//             request.locationLongitudeInPPM,
//             request.currentlyListed
//         );
// }

/// @notice Retrieves information about all cars.
/// @return An array of car information.
    function getAllCars() public view returns (Schemas.CarInfo[] memory) {
        return addresses.carService.getAllCars();
    }

/// @notice Retrieves information about available cars for a specific user.
/// @param user The address of the user.
/// @return An array of available car information for the specified user.
    function getAvailableCarsForUser(address user) public view returns (Schemas.CarInfo[] memory) {
        return addresses.carService.getAvailableCarsForUser(user);
    }

/// @notice Retrieves information about cars owned by the caller.
/// @return An array of car information owned by the caller.
    function getMyCars() public view returns (Schemas.CarInfoDTO[] memory) {
        return addresses.getCarsOwnedByUserWithEditability();
    }

/// @notice Retrieves detailed information about a car.
/// @param carId The ID of the car for which details are requested.
/// @return details An instance of `Schemas.CarDetails` containing the details of the specified car.
    function getCarDetails(uint carId) public view returns (Schemas.CarDetails memory) {
        return addresses.getCarDetails(carId);
    }

/// @notice Retrieves information about a trip by ID.
/// @param tripId The ID of the trip.
/// @return Trip information.
    function getTrip(uint256 tripId) public view returns (Schemas.TripDTO memory) {
        return RentalityTripsQuery.getTripDTO(addresses, tripId);
    }

/// @notice Retrieves information about trips where the caller is the guest.
/// @return An array of trip information.
    function getTripsAsGuest() public view returns (Schemas.TripDTO[] memory) {
        return addresses.getTripsByGuest(tx.origin);
    }

/// @notice Retrieves information about trips where the caller is the host.
/// @return An array of trip information.
    function getTripsAsHost() public view returns (Schemas.TripDTO[] memory) {
        return addresses.getTripsByHost(tx.origin);
    }

/// @notice Retrieves information about trips for a specific car.
/// @param carId The ID of the car.
/// @return An array of trip information for the specified car.
    function getTripsByCar(uint256 carId) public view returns (Schemas.Trip[] memory) {
        return addresses.getTripsByCar(carId);
    }

/// @notice Retrieves all claims where the caller is the host.
/// @dev The caller is assumed to be the host of the claims.
/// @return An array of FullClaimInfo containing information about each claim.
    function getMyClaimsAsHost() public view returns (Schemas.FullClaimInfo[] memory) {
        return addresses.getClaimsByHost(msg.sender);
    }

///  @notice Retrieves all claims where the caller is the guest.
///  @dev The caller is assumed to be the guest of the claims.
///  @return An array of FullClaimInfo containing information about each claim.
    function getMyClaimsAsGuest() public view returns (Schemas.FullClaimInfo[] memory) {
        return addresses.getClaimsByGuest(msg.sender);
    }

/// @notice Gets detailed information about a specific claim.
/// @dev Returns a structure containing information about the claim, associated trip, and car details.
/// @param claimId ID of the claim.
/// @return Full information about the claim.
    function getClaim(uint256 claimId) public view returns (Schemas.FullClaimInfo memory) {
        return addresses.getClaim(claimId);
    }

/// @notice Get contact information for a specific trip on the Rentality platform.
/// @param tripId The ID of the trip to retrieve contact information for.
/// @return guestPhoneNumber The phone number of the guest on the trip.
/// @return hostPhoneNumber The phone number of the host on the trip.
//// Refactoring for getTripContactInfo with RentalityContract
    function getTripContactInfo(
        uint256 tripId
    ) public view returns (string memory guestPhoneNumber, string memory hostPhoneNumber) {
        require(addresses.userService.isHostOrGuest(tx.origin), 'User is not a host or guest');

        Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);

        Schemas.KYCInfo memory guestInfo = addresses.userService.getKYCInfo(trip.guest);
        Schemas.KYCInfo memory hostInfo = addresses.userService.getKYCInfo(trip.host);

        return (guestInfo.mobilePhoneNumber, hostInfo.mobilePhoneNumber);
    }

/// @notice Retrieves KYC information for the caller.
/// @return KYC information for the caller.
    function getMyKYCInfo() external view returns (Schemas.KYCInfo memory) {
        return addresses.userService.getMyKYCInfo();
    }

/// @notice This function provides a detailed receipt of the trip, including payment information and trip details.
/// @param tripId The ID of the trip for which the receipt is requested.
/// @return tripReceipt An instance of `Schemas.TripReceiptDTO` containing the trip receipt details.
    function getTripReceipt(uint tripId) public view returns (Schemas.TripReceiptDTO memory) {
        return RentalityTripsQuery.fullFillTripReceipt(tripId, address(addresses.tripService));
    }

/// @notice Retrieves the cars owned by a specific host.
/// @dev This function returns an array of PublicHostCarDTO structs representing the cars owned by the host.
/// @param host The address of the host for whom to retrieve the cars.
/// @return An array of PublicHostCarDTO structs representing the cars owned by the host.
    function getCarsOfHost(address host) public view returns (Schemas.PublicHostCarDTO[] memory) {
        return addresses.carService.getCarsOfHost(host);
    }
/// @notice Get a discount.
/// @param user The address of user discount.
    function getDiscount(address user) public view returns (Schemas.BaseDiscount memory) {
        return addresses.paymentService.getBaseDiscount(user);
    }

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
        return
            RentalityUtils.calculatePayments(
            addresses,
            carId,
            daysOfTrip,
            currency,
            0
        );
    }
/// @notice Get chat information for trips hosted by the caller on the Rentality platform.
/// @return chatInfo An array of chat information for trips hosted by the caller.
    function getChatInfoForHost() public view returns (Schemas.ChatInfo[] memory) {
        Schemas.TripDTO[] memory trips = addresses.getTripsByHost(tx.origin);
        return RentalityUtils.populateChatInfo(false, addresses);
    }

/// @notice Get chat information for trips attended by the caller on the Rentality platform.
/// @return chatInfo An array of chat information for trips attended by the caller.
    function getChatInfoForGuest() public view returns (Schemas.ChatInfo[] memory) {
        Schemas.TripDTO[] memory trips = addresses.getTripsByGuest(tx.origin);
        return RentalityUtils.populateChatInfo(true, addresses);
    }

    function initialize(
        address carServiceAddress,
        address currencyConverterServiceAddress,
        address tripServiceAddress,
        address userServiceAddress,
        address paymentServiceAddress,
        address claimServiceAddress,
        address carDeliveryAddress
    ) public initializer {
        addresses = RentalityContract(
            RentalityCarToken(carServiceAddress),
            RentalityCurrencyConverter(currencyConverterServiceAddress),
            RentalityTripService(tripServiceAddress),
            RentalityUserService(userServiceAddress),
            RentalityPlatform(address(0)),
            RentalityPaymentService(payable(paymentServiceAddress)),
            RentalityClaimService(claimServiceAddress),
            RentalityAdminGateway(address(0)),
            RentalityCarDelivery(carDeliveryAddress),
            this
        );
    }

    function _authorizeUpgrade(address /*newImplementation*/) internal view override {
        require(addresses.userService.isAdmin(msg.sender), 'Only for Admin.');
    }
}