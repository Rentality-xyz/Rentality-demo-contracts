// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TripMain.sol";
import "./TripLib.sol";
import "./TripTypes.sol";
import "./../car/CarTypes.sol";
import "./../profile/UserProfileTypes.sol";
import "../common/CommonTypes.sol";
import "../../rentality_old/Schemas.sol";

interface ITripQueryUserProfileQuery {
    function getKYCInfo(address user) external view returns (UserProfileKYCInfo memory);
    function getMyFullKYCInfo(address user) external view returns (FullUserProfileInfo memory);
}

interface ITripQueryCarQuery {
    function getCar(uint256 id) external view returns (CarInfo memory);
}

interface ITripQueryGeoService {
    function getCarTimeZoneId(bytes32 hash) external view returns (string memory);
    function getLocationInfo(bytes32 hash) external view returns (Schemas.LocationInfo memory);
}

interface ITripQueryInsuranceService {
    function getTripInsurances(uint256 tripId) external view returns (Schemas.InsuranceInfo[] memory);
    function getInsurancePriceByTrip(uint256 tripId) external view returns (uint256);
}

interface ITripQueryPromoService {
    function getTripDiscount(uint256 tripId) external view returns (uint256);
    function getPromoTripInfo(uint256 tripId, address guest) external view returns (Schemas.PromoDTO memory);
}

interface ITripQueryDimoService {
    function getDimoTokenId(uint256 carId) external view returns (uint256);
}

interface ITripQueryPaymentService {
    function getTripTaxesDTO(uint256 tripId) external view returns (Schemas.TaxValue[] memory);
}

interface ITripQueryCurrencyConverter {
    function getCurrencyInfo(address currency) external view returns (Schemas.UserCurrencyDTO memory);
    function getToUsd(address tokenAddress, uint256 tokenValue, int256 tokenToUsd) external view returns (uint256);
}

interface ITripQueryHostInsurance {
    function getPaidToInsuranceByTripId(uint256 tripId) external view returns (uint256);
}

contract TripQuery {
    TripMain public immutable tripMain;
    ITripQueryUserProfileQuery public immutable userProfileQuery;
    ITripQueryCarQuery public immutable carQuery;
    ITripQueryGeoService public immutable geoService;
    ITripQueryInsuranceService public immutable insuranceService;
    ITripQueryPromoService public immutable promoService;
    ITripQueryDimoService public immutable dimoService;
    ITripQueryPaymentService public immutable paymentService;
    ITripQueryCurrencyConverter public immutable currencyConverter;
    ITripQueryHostInsurance public immutable hostInsurance;

    constructor(
        address tripMainAddress,
        address userServiceAddress,
        address carQueryAddress,
        address geoServiceAddress,
        address insuranceServiceAddress,
        address promoServiceAddress,
        address dimoServiceAddress,
        address paymentServiceAddress,
        address currencyConverterAddress,
        address hostInsuranceAddress
    ) {
        tripMain = TripMain(tripMainAddress);
        userProfileQuery = ITripQueryUserProfileQuery(userServiceAddress);
        carQuery = ITripQueryCarQuery(carQueryAddress);
        geoService = ITripQueryGeoService(geoServiceAddress);
        insuranceService = ITripQueryInsuranceService(insuranceServiceAddress);
        promoService = ITripQueryPromoService(promoServiceAddress);
        dimoService = ITripQueryDimoService(dimoServiceAddress);
        paymentService = ITripQueryPaymentService(paymentServiceAddress);
        currencyConverter = ITripQueryCurrencyConverter(currencyConverterAddress);
        hostInsurance = ITripQueryHostInsurance(hostInsuranceAddress);
    }

    function getTrip(uint256 tripId) public view returns (Trip memory) {
        return tripMain.getTrip(tripId);
    }

    function totalSupply() external view returns (uint256) {
        return tripMain.totalSupply();
    }

    function getActiveTrips(uint256 carId) external view returns (uint256[] memory) {
        return tripMain.getActiveTrips(carId);
    }

    function getCarTrips(uint256 carId) external view returns (uint256[] memory) {
        return tripMain.getCarTrips(carId);
    }

    function getActiveTripsByUser(address user) external view returns (uint256[] memory) {
        return tripMain.getActiveTripsByUser(user);
    }

    function getTripsByUser(address user) public view returns (uint256[] memory) {
        return tripMain.getTripsByUser(user);
    }

    function getTripContactInfo(uint256 tripId)
        external
        view
        returns (string memory guestPhoneNumber, string memory hostPhoneNumber)
    {
        Trip memory trip = getTrip(tripId);
        UserProfileKYCInfo memory guestInfo = userProfileQuery.getKYCInfo(trip.booking.customer);
        UserProfileKYCInfo memory hostInfo = userProfileQuery.getKYCInfo(trip.booking.provider);
        return (guestInfo.mobilePhoneNumber, hostInfo.mobilePhoneNumber);
    }

    function getTripDTO(uint256 tripId, address viewer) public view returns (TripDTO memory dto) {
        Trip memory trip = getTrip(tripId);
        CarInfo memory car = carQuery.getCar(trip.booking.resourceId);
        UserProfileKYCInfo memory guestInfo = userProfileQuery.getKYCInfo(trip.booking.customer);
        UserProfileKYCInfo memory hostInfo = userProfileQuery.getKYCInfo(trip.booking.provider);
        FullUserProfileInfo memory viewerInfo = userProfileQuery.getMyFullKYCInfo(viewer);

        bytes32 locationHash = car.car.locationHash;
        LocationInfo memory defaultLocation = _toLocationInfo(geoService.getLocationInfo(locationHash));

        dto.trip = trip;
        dto.guestPhotoUrl = guestInfo.profilePhoto;
        dto.hostPhotoUrl = hostInfo.profilePhoto;
        dto.metadataURI = car.asset.metadataURI;
        dto.timeZoneId = geoService.getCarTimeZoneId(locationHash);
        dto.hostDrivingLicenseNumber = hostInfo.licenseNumber;
        dto.hostDrivingLicenseExpirationDate = hostInfo.expirationDate;
        dto.guestDrivingLicenseNumber = guestInfo.licenseNumber;
        dto.guestDrivingLicenseExpirationDate = guestInfo.expirationDate;
        dto.model = car.car.model;
        dto.brand = car.car.brand;
        dto.yearOfProduction = car.car.yearOfProduction;
        dto.pickUpLocation = _resolveLocation(trip.pickUpHash, defaultLocation);
        dto.returnLocation = _resolveLocation(trip.returnHash, defaultLocation);
        dto.guestPhoneNumber = guestInfo.mobilePhoneNumber;
        dto.hostPhoneNumber = hostInfo.mobilePhoneNumber;
        dto.insurancesInfo = _toTripInsuranceInfos(insuranceService.getTripInsurances(tripId));
        dto.paidForInsuranceInUsdCents = insuranceService.getInsurancePriceByTrip(tripId);
        dto.guestDrivingLicenseIssueCountry = viewerInfo.additionalKYC.issueCountry;
        dto.promoDiscount = promoService.getTripDiscount(tripId);
        dto.dimoTokenId = dimoService.getDimoTokenId(trip.booking.resourceId);
        dto.taxesData = _toTripTaxValues(paymentService.getTripTaxesDTO(tripId));
        dto.currency = _toTripUserCurrency(currencyConverter.getCurrencyInfo(trip.paymentInfo.currencyType));
        dto.guestNickName = guestInfo.name;
        dto.hostNickName = hostInfo.name;
        dto.paidToInsuranceInUsdCents = currencyConverter.getToUsd(
            trip.paymentInfo.currencyType,
            hostInsurance.getPaidToInsuranceByTripId(tripId),
            trip.paymentInfo.currencyRate
        );
    }

    function getTripsAs(address user, bool host) public view returns (TripDTO[] memory) {
        uint256[] memory tripIds = getTripsByUser(user);
        TripDTO[] memory result = new TripDTO[](tripIds.length);
        uint256 index;

        for (uint256 i = 0; i < tripIds.length; i++) {
            Trip memory trip = getTrip(tripIds[i]);
            bool includeTrip = host ? trip.booking.provider == user : trip.booking.customer == user;
            if (!includeTrip) {
                continue;
            }

            result[index++] = getTripDTO(tripIds[i], user);
        }

        assembly ("memory-safe") {
            mstore(result, index)
        }

        return result;
    }

    function getAllTrips(Schemas.TripFilter memory filter, uint256 page, uint256 itemsPerPage)
        external
        view
        returns (Schemas.AllTripsDTO memory)
    {
        uint256 totalTripsCount = tripMain.totalSupply();
        uint256[] memory matchedTrips = new uint256[](totalTripsCount);
        uint256 counter;

        for (uint256 i = 1; i <= totalTripsCount; i++) {
            Trip memory trip = getTrip(i);
            if (_isTripMatch(filter, TripLib.toLegacyTrip(trip))) {
                matchedTrips[counter++] = i;
            }
        }

        if (counter == 0) {
            return Schemas.AllTripsDTO(new Schemas.AdminTripDTO[](0), 0);
        }

        uint256 totalPageCount = (counter + itemsPerPage - 1) / itemsPerPage;
        if (page > totalPageCount) {
            page = totalPageCount;
        }
        if (page < 1) {
            page = 1;
        }

        uint256 startIndex = (page - 1) * itemsPerPage;
        uint256 endIndex = startIndex + itemsPerPage;
        if (endIndex > counter) {
            endIndex = counter;
        }

        Schemas.AdminTripDTO[] memory result = new Schemas.AdminTripDTO[](endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            Trip memory trip = getTrip(matchedTrips[i]);
            Schemas.Trip memory legacyTrip = TripLib.toLegacyTrip(trip);
            CarInfo memory car = carQuery.getCar(legacyTrip.carId);
            result[i - startIndex] = Schemas.AdminTripDTO({
                trip: legacyTrip,
                carMetadataURI: car.asset.metadataURI,
                carLocation: geoService.getLocationInfo(car.car.locationHash),
                promoInfo: promoService.getPromoTripInfo(legacyTrip.tripId, legacyTrip.guest)
            });
        }

        return Schemas.AllTripsDTO(result, totalPageCount);
    }

    function getChatInfoFor(address user, bool host) external view returns (Schemas.ChatInfo[] memory result) {
        TripDTO[] memory trips = getTripsAs(user, host);
        result = new Schemas.ChatInfo[](trips.length);

        for (uint256 i = 0; i < trips.length; i++) {
            Trip memory trip = trips[i].trip;
            UserProfileKYCInfo memory guestInfo = userProfileQuery.getKYCInfo(trip.booking.customer);
            UserProfileKYCInfo memory hostInfo = userProfileQuery.getKYCInfo(trip.booking.provider);
            CarInfo memory car = carQuery.getCar(trip.booking.resourceId);

            Schemas.ChatInfo memory chatInfo;
            chatInfo.tripId = trip.booking.id;
            chatInfo.guestAddress = trip.booking.customer;
            chatInfo.guestName = guestInfo.surname;
            chatInfo.guestPhotoUrl = guestInfo.profilePhoto;
            chatInfo.hostAddress = trip.booking.provider;
            chatInfo.hostName = hostInfo.surname;
            chatInfo.hostPhotoUrl = hostInfo.profilePhoto;
            chatInfo.tripStatus = uint256(uint8(trip.status));
            chatInfo.carBrand = car.car.brand;
            chatInfo.carModel = car.car.model;
            chatInfo.carYearOfProduction = car.car.yearOfProduction;
            chatInfo.carMetadataUrl = car.asset.metadataURI;
            chatInfo.startDateTime = trip.booking.startDateTime;
            chatInfo.endDateTime = trip.booking.endDateTime;
            chatInfo.timeZoneId = car.car.timeZoneId;
            chatInfo.guestNickname = guestInfo.name;
            chatInfo.hostNickname = hostInfo.name;
            result[i] = chatInfo;
        }
    }

    function _isTripMatch(Schemas.TripFilter memory filter, Schemas.Trip memory trip) internal view returns (bool) {
        Schemas.LocationInfo memory locationInfo = geoService.getLocationInfo(carQuery.getCar(trip.carId).car.locationHash);

        return (
            (bytes(filter.location.country).length == 0 || _containsWord(_toLower(locationInfo.country), _toLower(filter.location.country))) &&
            (bytes(filter.location.state).length == 0 || _containsWord(_toLower(locationInfo.state), _toLower(filter.location.state))) &&
            (bytes(filter.location.city).length == 0 || _containsWord(_toLower(locationInfo.city), _toLower(filter.location.city))) &&
            (filter.startDateTime <= trip.startDateTime && filter.endDateTime >= trip.endDateTime) &&
            _matchesPaymentStatus(filter.paymentStatus, trip) &&
            _matchesAdminStatus(filter.status, trip)
        );
    }

    function _matchesPaymentStatus(Schemas.PaymentStatus paymentStatus, Schemas.Trip memory trip)
        internal
        pure
        returns (bool)
    {
        return
            paymentStatus == Schemas.PaymentStatus.Any ||
            (paymentStatus == Schemas.PaymentStatus.PaidToHost && trip.status == Schemas.TripStatus.Finished) ||
            (
                paymentStatus == Schemas.PaymentStatus.Prepayment &&
                    (
                        trip.status == Schemas.TripStatus.Created ||
                        trip.status == Schemas.TripStatus.Approved ||
                        trip.status == Schemas.TripStatus.CheckedInByHost ||
                        (trip.status == Schemas.TripStatus.CheckedInByGuest && trip.tripStartedBy == trip.guest) ||
                        (trip.status == Schemas.TripStatus.CheckedOutByGuest && trip.tripFinishedBy == trip.guest) ||
                        (trip.status == Schemas.TripStatus.CheckedOutByHost && trip.tripFinishedBy == trip.guest)
                    )
            ) ||
            (paymentStatus == Schemas.PaymentStatus.RefundToGuest && trip.status == Schemas.TripStatus.Canceled) ||
            (
                paymentStatus == Schemas.PaymentStatus.Unpaid &&
                    (
                        (trip.status == Schemas.TripStatus.CheckedInByGuest && trip.tripStartedBy == trip.host) ||
                        (trip.status == Schemas.TripStatus.CheckedOutByHost && trip.tripFinishedBy == trip.host)
                    )
            );
    }

    function _matchesAdminStatus(Schemas.AdminTripStatus status, Schemas.Trip memory trip)
        internal
        view
        returns (bool)
    {
        return
            status == Schemas.AdminTripStatus.Any ||
            (status == Schemas.AdminTripStatus.Created && trip.status == Schemas.TripStatus.Created) ||
            (status == Schemas.AdminTripStatus.Approved && trip.status == Schemas.TripStatus.Approved) ||
            (status == Schemas.AdminTripStatus.CheckedInByHost && trip.status == Schemas.TripStatus.CheckedInByHost) ||
            (
                status == Schemas.AdminTripStatus.CheckedInByGuest &&
                    trip.status == Schemas.TripStatus.CheckedInByGuest &&
                    trip.tripStartedBy == trip.guest
            ) ||
            (
                status == Schemas.AdminTripStatus.CheckedOutByGuest &&
                    trip.status == Schemas.TripStatus.CheckedOutByGuest &&
                    trip.tripFinishedBy == trip.guest
            ) ||
            (
                status == Schemas.AdminTripStatus.CheckedOutByHost &&
                    trip.status == Schemas.TripStatus.CheckedOutByHost &&
                    trip.tripFinishedBy == trip.guest
            ) ||
            (status == Schemas.AdminTripStatus.Finished && trip.status == Schemas.TripStatus.Finished) ||
            (
                status == Schemas.AdminTripStatus.GuestCanceledBeforeApprove &&
                    trip.status == Schemas.TripStatus.Canceled &&
                    trip.approvedDateTime == 0 &&
                    trip.rejectedBy == trip.guest
            ) ||
            (
                status == Schemas.AdminTripStatus.HostCanceledBeforeApprove &&
                    trip.status == Schemas.TripStatus.Canceled &&
                    trip.approvedDateTime == 0 &&
                    trip.rejectedBy == trip.host
            ) ||
            (
                status == Schemas.AdminTripStatus.GuestCanceledAfterApprove &&
                    trip.status == Schemas.TripStatus.Canceled &&
                    trip.approvedDateTime > 0 &&
                    trip.rejectedBy == trip.guest
            ) ||
            (
                status == Schemas.AdminTripStatus.HostCanceledAfterApprove &&
                    trip.status == Schemas.TripStatus.Canceled &&
                    trip.approvedDateTime > 0 &&
                    trip.rejectedBy == trip.host
            ) ||
            (
                status == Schemas.AdminTripStatus.CompletedWithoutGuestConfirmation &&
                    trip.status == Schemas.TripStatus.CheckedOutByHost &&
                    trip.tripFinishedBy == trip.host
            ) ||
            (
                status == Schemas.AdminTripStatus.CompletedByGuest &&
                    trip.status == Schemas.TripStatus.Finished &&
                    trip.tripFinishedBy == trip.host
            ) ||
            (
                status == Schemas.AdminTripStatus.CompletedByAdmin &&
                    trip.status == Schemas.TripStatus.Finished &&
                    tripMain.isCompletedByAdmin(trip.tripId)
            );
    }

    function _containsWord(string memory source, string memory word) internal pure returns (bool) {
        bytes memory sourceBytes = bytes(source);
        bytes memory wordBytes = bytes(word);
        if (wordBytes.length == 0) {
            return true;
        }
        if (wordBytes.length > sourceBytes.length) {
            return false;
        }

        for (uint256 i = 0; i <= sourceBytes.length - wordBytes.length; i++) {
            bool matched = true;
            for (uint256 j = 0; j < wordBytes.length; j++) {
                if (sourceBytes[i + j] != wordBytes[j]) {
                    matched = false;
                    break;
                }
            }
            if (matched) {
                return true;
            }
        }
        return false;
    }

    function _toLower(string memory value) internal pure returns (string memory) {
        bytes memory input = bytes(value);
        bytes memory output = new bytes(input.length);
        for (uint256 i = 0; i < input.length; i++) {
            bytes1 char = input[i];
            output[i] = char >= 0x41 && char <= 0x5A ? bytes1(uint8(char) + 32) : char;
        }
        return string(output);
    }

    function _resolveLocation(bytes32 hash, LocationInfo memory fallbackLocation) internal view returns (LocationInfo memory) {
        LocationInfo memory location = _toLocationInfo(geoService.getLocationInfo(hash));
        if (bytes(location.latitude).length == 0) {
            return fallbackLocation;
        }
        return location;
    }

    function _toLocationInfo(Schemas.LocationInfo memory location) internal pure returns (LocationInfo memory) {
        return LocationInfo({
            userAddress: location.userAddress,
            country: location.country,
            state: location.state,
            city: location.city,
            latitude: location.latitude,
            longitude: location.longitude,
            timeZoneId: location.timeZoneId
        });
    }

    function _toTripInsuranceInfos(Schemas.InsuranceInfo[] memory insurances)
        internal
        pure
        returns (TripInsuranceInfo[] memory result)
    {
        result = new TripInsuranceInfo[](insurances.length);
        for (uint256 i = 0; i < insurances.length; i++) {
            result[i] = TripInsuranceInfo({
                companyName: insurances[i].companyName,
                policyNumber: insurances[i].policyNumber,
                photo: insurances[i].photo,
                comment: insurances[i].comment,
                insuranceType: uint8(insurances[i].insuranceType),
                createdTime: insurances[i].createdTime,
                createdBy: insurances[i].createdBy
            });
        }
    }

    function _toTripTaxValues(Schemas.TaxValue[] memory taxes)
        internal
        pure
        returns (TripTaxValue[] memory result)
    {
        result = new TripTaxValue[](taxes.length);
        for (uint256 i = 0; i < taxes.length; i++) {
            result[i] = TripTaxValue({name: taxes[i].name, value: taxes[i].value, taxType: uint8(taxes[i].tType)});
        }
    }

    function _toTripUserCurrency(Schemas.UserCurrencyDTO memory currency)
        internal
        pure
        returns (TripUserCurrency memory)
    {
        return TripUserCurrency({currency: currency.currency, name: currency.name, initialized: currency.initialized});
    }
}


