const { ethers } = require('hardhat')

async function main() {

  const contractName = "RentalityCarToken";
  const linkToken = "0x779877A7B0D9E8603169DdbD7836e478b4624789";
  const linkOracle = "0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD";
  const geo_c = "0xeeD4ad2E7839ec5f9808b8336CAD4a6A298F882d";
  const carSer = "0x58dfa3Dba75Cef80AeE48C95562c989a2F17b2d6";
  const wrong_location = 'Fake City, 12345, Imaginary Country';

  const [deployer] = await ethers.getSigners();
  const balance = await deployer.getBalance();
  console.log(
    "Deployer address is:",
    deployer.getAddress(),
    " with balance:",
    balance
  );


  const utils = "0xdA45508CE22156dd21A81f588e9Dce2396d0fecd";


   const geo_contract = await ethers.getContractFactory("RentalityGeoService");
  //   {
  //     libraries:
  //       {
  //         RentalityUtils: utils
  //       }
  //   });

  const geoContract = await geo_contract.deploy();
  // const geoContract = await geo_contract.attach(geo_c);

  const geoAdd = geoContract.address;
  console.log("geo addr", geoAdd);

  const CarService = await ethers.getContractFactory(contractName);

  const carService = await CarService.deploy(geoAdd,{gasLimit: 20000000});

  console.log("car service", carService.address)
  //
  // let carService = CarService.attach(carSer);
  //
  //
  //
  // const car_req = getMockCarRequest(2);
  //
  // let addTx =  await carService.addCar(car_req, {gasLimit: 5000000});
  // let car_add_result = await addTx.wait();
  // //
  // console.log("logs ",car_add_result.logs);



      // console.log("GOT ChainLink Response");
      // let parse = await geoContract.parseGeoResponse(3);
      // await parse.wait();
      //
      // let geo_result = await carService.verifyGeo(1);
      // await geo_result.wait();
      //
      // console.log("geo result", geo_result);

      // let allCars = await carService.getAllCars();

      // console.log("ALL CARS", allCars);

      //



}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


function getMockCarRequest(seed) {
  const seedStr = seed?.toString() ?? ''
  const seedInt = Number(seed) ?? 0

  const TOKEN_URI = 'TOKEN_URI' + seedStr
  const VIN_NUMBER = 'VIN_NUMBER' + seedStr + '1'
  const BRAND = 'BRAND' + seedStr
  const MODEL = 'MODEL' + seedStr
  const YEAR = '200' + seedStr
  const PRICE_PER_DAY = seedInt * 100 + 2
  const DEPOSIT = seedInt * 100 + 3
  const TANK_VOLUME = seedInt * 100 + 4
  const FUEL_PRICE = seedInt * 100 + 5
  const DISTANCE_INCLUDED = seedInt * 100 + 6
  const location = '1600 Pennsylvania Avenue NW, Washington, D.C., 20500'
  const apiKey = 'AIzaSyB4Cfr7WfvqakEX-Zu7w2Uva_30zPg3d_s'

  return {
    tokenUri: TOKEN_URI,
    carVinNumber: VIN_NUMBER,
    brand: BRAND,
    model: MODEL,
    yearOfProduction: YEAR,
    pricePerDayInUsdCents: PRICE_PER_DAY,
    securityDepositPerTripInUsdCents: DEPOSIT,
    tankVolumeInGal: TANK_VOLUME,
    fuelPricePerGalInUsdCents: FUEL_PRICE,
    milesIncludedPerDay: DISTANCE_INCLUDED,
    locationAddress: location,
    geoApiKey: apiKey,
  }
}