// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '../common/CommonTypes.sol';
import '../base/asset/AssetTypes.sol';
import '../car/CarTypes.sol';
import '../profile/UserProfileTypes.sol';
import '../trip/TripTypes.sol';

interface ICarQueryFacet2Main {
  function exists(uint256 id) external view returns (bool);
  function totalSupply() external view returns (uint256);
  function getAsset(uint256 id) external view returns (Asset memory);
  function getOwner(uint256 id) external view returns (address);
  function getCarData(uint256 id) external view returns (CarData memory);
  function tokenURI(uint256 id) external view returns (string memory);
}

interface ICarQueryFacet2PricingService {
  function calculateSumWithDiscount(address user, uint64 daysOfTrip, uint64 value) external view returns (uint64);
}

interface ICarQueryFacet2TripQuery {
  function getActiveTrips(uint256 carId) external view returns (uint256[] memory);
  function getTrip(uint256 tripId) external view returns (Trip memory);
}

interface ICarQueryFacet2UserProfileQuery {
  function getKYCInfo(address user) external view returns (UserProfileKYCInfo memory);
}

interface ICarQueryFacet2GeoService {
  function getLocationInfo(bytes32 hash) external view returns (LocationInfo memory);
  function getCarCoordinateValidity(uint256 carId) external view returns (bool);
}

interface ICarQueryFacet2DimoService {
  function getDimoTokenId(uint256 carId) external view returns (uint256);
}

contract CarQueryFacet2 {
  ICarQueryFacet2Main public immutable carMain;

  constructor(address carMainAddress) {
    carMain = ICarQueryFacet2Main(carMainAddress);
  }

  function getUniqCarsBrand() external view returns (string[] memory brandsArray) {
    uint256 supply = carMain.totalSupply();
    string[] memory temp = new string[](supply);
    uint256 count;

    for (uint256 i = 1; i <= supply; i++) {
      if (!carMain.exists(i)) {
        continue;
      }

      string memory brand = carMain.getCarData(i).brand;
      bool existsBrand;
      for (uint256 j = 0; j < count; j++) {
        if (_compareStrings(temp[j], brand)) {
          existsBrand = true;
          break;
        }
      }

      if (!existsBrand) {
        temp[count++] = brand;
      }
    }

    assembly ('memory-safe') {
      mstore(temp, count)
    }
    return temp;
  }

  function getUniqModelsByBrand(string memory brand) external view returns (string[] memory modelsArray) {
    uint256 supply = carMain.totalSupply();
    string[] memory temp = new string[](supply);
    uint256 count;

    for (uint256 i = 1; i <= supply; i++) {
      if (!carMain.exists(i)) {
        continue;
      }

      CarData memory car = carMain.getCarData(i);
      if (!_compareStrings(car.brand, brand)) {
        continue;
      }

      bool existsModel;
      for (uint256 j = 0; j < count; j++) {
        if (_compareStrings(temp[j], car.model)) {
          existsModel = true;
          break;
        }
      }

      if (!existsModel) {
        temp[count++] = car.model;
      }
    }

    assembly ('memory-safe') {
      mstore(temp, count)
    }
    return temp;
  }

  function getFilterInfo(address pricingServiceAddress, uint64 duration)
    external
    view
    returns (CarFilterInfo memory)
  {
    uint256 supply = carMain.totalSupply();
    if (supply == 0) {
      return CarFilterInfo({maxCarPrice: 0, minCarYearOfProduction: 0});
    }

    ICarQueryFacet2PricingService pricingService = ICarQueryFacet2PricingService(pricingServiceAddress);
    uint64 maxCarPrice;
    uint256 minCarYearOfProduction = type(uint256).max;
    bool foundCar;

    for (uint256 i = 1; i <= supply; i++) {
      if (!carMain.exists(i)) {
        continue;
      }

      CarData memory car = carMain.getCarData(i);
      uint64 sumWithDiscount = pricingService.calculateSumWithDiscount(
        carMain.getOwner(i),
        duration,
        car.pricePerDayInUsdCents
      );

      if (sumWithDiscount > maxCarPrice) {
        maxCarPrice = sumWithDiscount;
      }
      if (car.yearOfProduction < minCarYearOfProduction) {
        minCarYearOfProduction = car.yearOfProduction;
      }
      foundCar = true;
    }

    return CarFilterInfo({
      maxCarPrice: maxCarPrice,
      minCarYearOfProduction: foundCar ? minCarYearOfProduction : 0
    });
  }

  function getAllCarsForAdmin(
    address userProfileQueryAddress,
    address geoServiceAddress,
    address dimoServiceAddress,
    uint256 page,
    uint256 itemsPerPage
  ) external view returns (AllCarsInfo memory) {
    uint256 totalCars = carMain.totalSupply();
    uint256 totalExistingCars;

    for (uint256 i = 1; i <= totalCars; i++) {
      if (carMain.exists(i)) {
        totalExistingCars++;
      }
    }

    uint256 totalPageCount = totalExistingCars == 0 ? 0 : (totalExistingCars + itemsPerPage - 1) / itemsPerPage;
    if (page > totalPageCount) {
      page = totalPageCount;
    }
    if (page < 1) {
      page = 1;
    }

    AdminCarInfo[] memory cars = new AdminCarInfo[](itemsPerPage);
    uint256 collected;
    uint256 currentId = 1;
    uint256 toSkip = (page - 1) * itemsPerPage;

    while (toSkip > 0 && currentId <= totalCars) {
      if (carMain.exists(currentId)) {
        toSkip--;
      }
      currentId++;
    }

    while (collected < itemsPerPage && currentId <= totalCars) {
      if (carMain.exists(currentId)) {
        cars[collected] = AdminCarInfo({
          car: _getCarDetails(userProfileQueryAddress, geoServiceAddress, dimoServiceAddress, currentId),
          carMetadataURI: carMain.tokenURI(currentId)
        });
        collected++;
      }
      currentId++;
    }

    assembly ('memory-safe') {
      mstore(cars, collected)
    }

    return AllCarsInfo(cars, totalPageCount);
  }

  function isCarEditable(address tripQueryAddress, uint256 carId) public view returns (bool) {
    ICarQueryFacet2TripQuery tripQuery = ICarQueryFacet2TripQuery(tripQueryAddress);
    uint256[] memory carTrips = tripQuery.getActiveTrips(carId);

    for (uint256 i = 0; i < carTrips.length; i++) {
      Trip memory tripInfo = tripQuery.getTrip(carTrips[i]);
      if (
        tripInfo.booking.resourceId == carId &&
        (
          tripInfo.status != TripStatus.Finished &&
          tripInfo.status != TripStatus.Canceled &&
          (tripInfo.status != TripStatus.CheckedOutByHost || tripInfo.booking.provider != tripInfo.tripFinishedBy)
        )
      ) {
        return false;
      }
    }

    return true;
  }

  function _getCarDetails(
    address userProfileQueryAddress,
    address geoServiceAddress,
    address dimoServiceAddress,
    uint256 carId
  ) internal view returns (CarDetails memory) {
    Asset memory asset = carMain.getAsset(carId);
    CarData memory car = carMain.getCarData(carId);
    UserProfileKYCInfo memory hostKyc = ICarQueryFacet2UserProfileQuery(userProfileQueryAddress).getKYCInfo(asset.owner);
    ICarQueryFacet2GeoService geoService = ICarQueryFacet2GeoService(geoServiceAddress);

    return CarDetails({
      carId: carId,
      hostName: hostKyc.name,
      hostPhotoUrl: hostKyc.profilePhoto,
      host: asset.owner,
      brand: car.brand,
      model: car.model,
      yearOfProduction: car.yearOfProduction,
      pricePerDayInUsdCents: car.pricePerDayInUsdCents,
      securityDepositPerTripInUsdCents: car.securityDepositPerTripInUsdCents,
      milesIncludedPerDay: car.milesIncludedPerDay,
      engineType: car.engineType,
      engineParams: car.engineParams,
      geoVerified: geoService.getCarCoordinateValidity(carId),
      currentlyListed: car.currentlyListed,
      locationInfo: geoService.getLocationInfo(car.locationHash),
      carVinNumber: car.carVinNumber,
      carMetadataURI: carMain.tokenURI(carId),
      dimoTokenId: ICarQueryFacet2DimoService(dimoServiceAddress).getDimoTokenId(carId)
    });
  }

  function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(bytes(a)) == keccak256(bytes(b));
  }

}
