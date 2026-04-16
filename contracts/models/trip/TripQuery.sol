// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TripMain.sol";
import "./TripTypes.sol";
import "./../car/CarTypes.sol";
import "../common/CommonTypes.sol";
import "../../rentality_old/Schemas.sol";

interface ITripQueryUserService {
    function getKYCInfo(address user) external view returns (Schemas.KYCInfo memory);
    function getMyFullKYCInfo(address user) external view returns (Schemas.FullKYCInfoDTO memory);
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
    ITripQueryUserService public immutable userService;
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
        userService = ITripQueryUserService(userServiceAddress);
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
        Schemas.KYCInfo memory guestInfo = userService.getKYCInfo(trip.booking.customer);
        Schemas.KYCInfo memory hostInfo = userService.getKYCInfo(trip.booking.provider);
        return (guestInfo.mobilePhoneNumber, hostInfo.mobilePhoneNumber);
    }

    function getTripDTO(uint256 tripId, address viewer) public view returns (TripDTO memory dto) {
        Trip memory trip = getTrip(tripId);
        CarInfo memory car = carQuery.getCar(trip.booking.resourceId);
        Schemas.KYCInfo memory guestInfo = userService.getKYCInfo(trip.booking.customer);
        Schemas.KYCInfo memory hostInfo = userService.getKYCInfo(trip.booking.provider);
        Schemas.FullKYCInfoDTO memory viewerInfo = userService.getMyFullKYCInfo(viewer);

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

    function getChatInfoFor(address user, bool host) external view returns (Schemas.ChatInfo[] memory result) {
        TripDTO[] memory trips = getTripsAs(user, host);
        result = new Schemas.ChatInfo[](trips.length);

        for (uint256 i = 0; i < trips.length; i++) {
            Trip memory trip = trips[i].trip;
            Schemas.KYCInfo memory guestInfo = userService.getKYCInfo(trip.booking.customer);
            Schemas.KYCInfo memory hostInfo = userService.getKYCInfo(trip.booking.provider);
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
