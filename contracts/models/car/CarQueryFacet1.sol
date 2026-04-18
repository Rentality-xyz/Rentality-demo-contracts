pragma solidity ^0.8.20;

import "../common/CommonTypes.sol";
import "../profile/UserProfileTypes.sol";
import "../pricing/RentalPricingTypes.sol";
import "../base/insurance/InsuranceTypes.sol";
import "../trip/TripTypes.sol";
import "./CarLib.sol";
import "./CarTypes.sol";
import "../../rentality_old/Schemas.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface ICarQueryFacet1Main {
    function totalSupply() external view returns (uint256);
    function getGeoVerifierAddress() external view returns (address);
    function getEngineValidatorAddress() external view returns (address);
    function getUserDeliveryPrices(address user) external view returns (DeliveryPrices memory);
}

interface ICarQueryFacet1CarQuery {
    function getCar(uint256 id) external view returns (CarInfo memory);
    function fetchAvailableCarsForUser(address user, CarSearchParams calldata searchParams, uint256 from, uint256 to)
        external
        view
        returns (CarInfo[] memory);
}

interface ICarQueryFacet1TripQuery {
    function getActiveTrips(uint256 carId) external view returns (uint256[] memory);
    function getTrip(uint256 tripId) external view returns (Trip memory);
}

interface ICarQueryFacet1UserProfileQuery {
    function getKYCInfo(address user) external view returns (UserProfileKYCInfo memory);
    function getUserCurrency(address user) external view returns (address currency, bool initialized);
}

interface ICarQueryFacet1PricingService {
    function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64);
    function defineTaxesType(address carService, uint256 carId) external view returns (uint256);
    function calculateTaxesDTO(uint256 taxId, uint64 tripDays, uint64 totalCost)
        external
        view
        returns (uint64 totalTax, RentalTaxValue[] memory taxes);
    function getBaseDiscount(address user) external view returns (RentalBaseDiscount memory);
}

interface ICarQueryFacet1InsuranceService {
    function getInsuranceRequirement(uint256 objectId) external view returns (InsuranceRequirement memory);
    function isGuestHasInsurance(address guest) external view returns (bool);
}

interface ICarQueryFacet1DimoService {
    function getDimoTokenId(uint256 carId) external view returns (uint256);
}

interface ICarQueryFacet1GeoService {
    function getLocationInfo(bytes32 hash) external view returns (Schemas.LocationInfo memory);
}

interface ICarQueryFacet1CurrencyConverter {
    function getCurrencyInfo(address currency) external view returns (Schemas.UserCurrencyDTO memory);
    function getDefaultCurrency() external view returns (Schemas.UserCurrencyDTO memory);
}

interface ICarQueryFacet1EngineService {
    function getFuelPriceFromEngineParams(uint8 eType, uint64[] memory engineParams) external view returns (uint64);
}

contract CarQueryFacet1 {
    ICarQueryFacet1Main public immutable carMain;
    ICarQueryFacet1CarQuery public immutable carQuery;

    constructor(address carMainAddress, address carQueryAddress) {
        carMain = ICarQueryFacet1Main(carMainAddress);
        carQuery = ICarQueryFacet1CarQuery(carQueryAddress);
    }

    function buildAvailableCarDTO(
        CarAvailabilityContext memory context,
        uint256 carId,
        uint64 startDateTime,
        uint64 endDateTime,
        string memory metadataURI,
        Schemas.LocationInfo memory pickUpInfo,
        Schemas.LocationInfo memory returnInfo,
        address user
    ) external view returns (Schemas.AvailableCarDTO memory) {
        CarInfo memory car = carQuery.getCar(carId);
        return _buildAvailableCarDTO(
            context,
            car,
            startDateTime,
            endDateTime,
            metadataURI,
            pickUpInfo,
            returnInfo,
            user
        );
    }

    function searchAvailableCarsWithDelivery(
        CarAvailabilityContext memory context,
        address user,
        uint64 startDateTime,
        uint64 endDateTime,
        CarSearchParams memory searchParams,
        Schemas.LocationInfo memory pickUpInfo,
        Schemas.LocationInfo memory returnInfo,
        uint256 from,
        uint256 to
    ) external view returns (Schemas.SearchCarsWithDistanceDTO memory result) {
        CarInfo[] memory candidates = carQuery.fetchAvailableCarsForUser(user, searchParams, from, to);
        uint256 totalCarsSupply = carMain.totalSupply();
        if (candidates.length == 0) {
            return Schemas.SearchCarsWithDistanceDTO({
                cars: new Schemas.SearchCarWithDistance[](0),
                totalCarsSupply: totalCarsSupply
            });
        }

        uint256[] memory temp = new uint256[](candidates.length);
        uint256 count;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (!_hasIntersectTrips(context, candidates[i], startDateTime, endDateTime)) {
                temp[count++] = i;
            }
        }

        Schemas.SearchCar[] memory cars = new Schemas.SearchCar[](count);
        for (uint256 i = 0; i < count; i++) {
            CarInfo memory car = candidates[temp[i]];
            Schemas.AvailableCarDTO memory availableCar = _buildAvailableCarDTO(
                context,
                car,
                startDateTime,
                endDateTime,
                car.asset.metadataURI,
                pickUpInfo,
                returnInfo,
                user
            );
            cars[i] = _toSearchCar(availableCar, car.car.engineParams);
        }

        return Schemas.SearchCarsWithDistanceDTO({
            cars: _sortCarsByDistance(cars, searchParams.userLocation),
            totalCarsSupply: totalCarsSupply
        });
    }

    function _buildAvailableCarDTO(
        CarAvailabilityContext memory context,
        CarInfo memory car,
        uint64 startDateTime,
        uint64 endDateTime,
        string memory metadataURI,
        Schemas.LocationInfo memory pickUpInfo,
        Schemas.LocationInfo memory returnInfo,
        address user
    ) internal view returns (Schemas.AvailableCarDTO memory) {
        ICarQueryFacet1UserProfileQuery userProfileQuery = ICarQueryFacet1UserProfileQuery(context.userProfileQuery);
        ICarQueryFacet1PricingService pricingService = ICarQueryFacet1PricingService(context.pricingService);
        ICarQueryFacet1InsuranceService insuranceService = ICarQueryFacet1InsuranceService(context.insuranceService);
        ICarQueryFacet1GeoService geoService = ICarQueryFacet1GeoService(context.geoService);

        address host = car.asset.owner;
        uint64 totalTripDays = uint64(Math.ceilDiv(endDateTime - startDateTime, 1 days));
        totalTripDays = totalTripDays == 0 ? 1 : totalTripDays;

        DeliveryPrices memory deliveryPrices = carMain.getUserDeliveryPrices(host);
        Schemas.LocationInfo memory location = geoService.getLocationInfo(car.car.locationHash);
        int128 distance = CarLib.calculateDistance(
            location.latitude,
            location.longitude,
            pickUpInfo.latitude,
            pickUpInfo.longitude
        );

        uint64 pickUp = 0;
        uint64 dropOf = 0;
        if (bytes(pickUpInfo.latitude).length != 0 || bytes(returnInfo.longitude).length != 0) {
            (pickUp, dropOf) = CarLib.calculateDeliveryPrices(
                _toCommonLocationInfo(pickUpInfo),
                _toCommonLocationInfo(returnInfo),
                location.latitude,
                location.longitude,
                deliveryPrices
            );
        }

        uint64 priceWithDiscount = pricingService.calculateSumWithDiscount(
            host,
            totalTripDays,
            car.car.pricePerDayInUsdCents
        );

        uint256 taxId = pricingService.defineTaxesType(context.carTaxAdapter, car.asset.id);
        uint64 totalTax = 0;
        Schemas.TaxValue[] memory taxes = new Schemas.TaxValue[](0);
        if (taxId != 0) {
            RentalTaxValue[] memory rentalTaxes;
            (totalTax, rentalTaxes) = pricingService.calculateTaxesDTO(
                taxId,
                totalTripDays,
                priceWithDiscount + pickUp + dropOf
            );
            taxes = _toLegacyTaxes(rentalTaxes);
        }

        UserProfileKYCInfo memory hostKyc = userProfileQuery.getKYCInfo(host);
        InsuranceRequirement memory insuranceRequirement = insuranceService.getInsuranceRequirement(car.asset.id);
        RentalBaseDiscount memory discount = pricingService.getBaseDiscount(host);
        uint256 dimoTokenId = ICarQueryFacet1DimoService(context.dimoService).getDimoTokenId(car.asset.id);
        (address selectedCurrency, bool hasSelectedCurrency) = userProfileQuery.getUserCurrency(host);
        Schemas.UserCurrencyDTO memory hostCurrency = hasSelectedCurrency
            ? ICarQueryFacet1CurrencyConverter(context.currencyConverter).getCurrencyInfo(selectedCurrency)
            : ICarQueryFacet1CurrencyConverter(context.currencyConverter).getDefaultCurrency();
        if (hasSelectedCurrency) {
            hostCurrency.initialized = true;
        }
        uint64 fuelPrice = ICarQueryFacet1EngineService(carMain.getEngineValidatorAddress())
            .getFuelPriceFromEngineParams(car.car.engineType, car.car.engineParams);

        return Schemas.AvailableCarDTO({
            carId: car.asset.id,
            brand: car.car.brand,
            model: car.car.model,
            yearOfProduction: car.car.yearOfProduction,
            pricePerDayInUsdCents: car.car.pricePerDayInUsdCents,
            pricePerDayWithDiscount: priceWithDiscount / totalTripDays,
            tripDays: totalTripDays,
            totalPriceWithDiscount: priceWithDiscount,
            securityDepositPerTripInUsdCents: car.car.securityDepositPerTripInUsdCents,
            engineType: car.car.engineType,
            milesIncludedPerDay: car.car.milesIncludedPerDay,
            host: host,
            hostName: hostKyc.name,
            hostPhotoUrl: hostKyc.profilePhoto,
            metadataURI: metadataURI,
            underTwentyFiveMilesInUsdCents: deliveryPrices.underTwentyFiveMilesInUsdCents,
            aboveTwentyFiveMilesInUsdCents: deliveryPrices.aboveTwentyFiveMilesInUsdCents,
            pickUp: pickUp,
            dropOf: dropOf,
            insuranceIncluded: car.car.insuranceIncluded,
            locationInfo: location,
            insuranceInfo: Schemas.InsuranceCarInfo({
                required: insuranceRequirement.required,
                priceInUsdCents: insuranceRequirement.priceInUsdCents
            }),
            fuelPrice: fuelPrice,
            carDiscounts: Schemas.BaseDiscount({
                threeDaysDiscount: discount.threeDaysDiscount,
                sevenDaysDiscount: discount.sevenDaysDiscount,
                thirtyDaysDiscount: discount.thirtyDaysDiscount,
                initialized: discount.initialized
            }),
            distance: distance,
            isGuestHasInsurance: insuranceService.isGuestHasInsurance(user),
            dimoTokenId: dimoTokenId,
            taxes: taxes,
            totalTax: totalTax,
            hostCurrency: hostCurrency
        });
    }

    function _hasIntersectTrips(
        CarAvailabilityContext memory context,
        CarInfo memory car,
        uint64 startDateTime,
        uint64 endDateTime
    ) internal view returns (bool) {
        ICarQueryFacet1TripQuery tripQuery = ICarQueryFacet1TripQuery(context.tripQuery);
        uint256[] memory carTrips = tripQuery.getActiveTrips(car.asset.id);
        uint32 timeBuffer = car.car.timeBufferBetweenTripsInSec;

        for (uint256 i = 0; i < carTrips.length; i++) {
            Trip memory trip = tripQuery.getTrip(carTrips[i]);
            if (
                trip.booking.resourceId == car.asset.id
                    && trip.booking.endDateTime + timeBuffer > startDateTime
                    && trip.booking.startDateTime < endDateTime
            ) {
                return true;
            }
        }

        return false;
    }

    function _sortCarsByDistance(
        Schemas.SearchCar[] memory cars,
        LocationInfo memory pickUpLocation
    ) internal pure returns (Schemas.SearchCarWithDistance[] memory result) {
        result = new Schemas.SearchCarWithDistance[](cars.length);
        int128[] memory distances = new int128[](cars.length);

        for (uint256 i = 0; i < cars.length; i++) {
            result[i] = Schemas.SearchCarWithDistance({car: cars[i], distance: 0});
            distances[i] = CarLib.calculateDistance(
                cars[i].locationInfo.latitude,
                cars[i].locationInfo.longitude,
                pickUpLocation.latitude,
                pickUpLocation.longitude
            );
            result[i].distance = int256(distances[i]);
        }

        for (uint256 i = 0; i < result.length; i++) {
            for (uint256 j = i + 1; j < result.length; j++) {
                if (result[i].distance > result[j].distance) {
                    Schemas.SearchCarWithDistance memory temp = result[i];
                    result[i] = result[j];
                    result[j] = temp;
                }
            }
        }
    }

    function _toSearchCar(Schemas.AvailableCarDTO memory car, uint64[] memory engineParams)
        internal
        pure
        returns (Schemas.SearchCar memory)
    {
        return Schemas.SearchCar({
            carId: car.carId,
            brand: car.brand,
            model: car.model,
            yearOfProduction: car.yearOfProduction,
            pricePerDayInUsdCents: car.pricePerDayInUsdCents,
            pricePerDayWithDiscount: car.pricePerDayWithDiscount,
            tripDays: car.tripDays,
            totalPriceWithDiscount: car.totalPriceWithDiscount,
            taxes: car.totalTax,
            securityDepositPerTripInUsdCents: car.securityDepositPerTripInUsdCents,
            engineType: car.engineType,
            milesIncludedPerDay: car.milesIncludedPerDay,
            host: car.host,
            hostName: car.hostName,
            hostPhotoUrl: car.hostPhotoUrl,
            metadataURI: car.metadataURI,
            underTwentyFiveMilesInUsdCents: car.underTwentyFiveMilesInUsdCents,
            aboveTwentyFiveMilesInUsdCents: car.aboveTwentyFiveMilesInUsdCents,
            pickUp: car.pickUp,
            dropOf: car.dropOf,
            insuranceIncluded: car.insuranceIncluded,
            locationInfo: car.locationInfo,
            insuranceInfo: car.insuranceInfo,
            isGuestHasInsurance: car.isGuestHasInsurance,
            dimoTokenId: car.dimoTokenId,
            hostCurrency: car.hostCurrency,
            fuelPrice: car.fuelPrice,
            carDiscounts: car.carDiscounts,
            taxesInfo: car.taxes,
            engineParams: engineParams
        });
    }

    function _toCommonLocationInfo(Schemas.LocationInfo memory location) internal pure returns (LocationInfo memory) {
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

    function _toLegacyTaxes(RentalTaxValue[] memory taxes) internal pure returns (Schemas.TaxValue[] memory) {
        Schemas.TaxValue[] memory result = new Schemas.TaxValue[](taxes.length);

        for (uint256 i = 0; i < taxes.length; i++) {
            result[i] = Schemas.TaxValue({
                name: taxes[i].name,
                value: taxes[i].value,
                tType: Schemas.TaxesType(uint8(taxes[i].tType))
            });
        }

        return result;
    }
}

