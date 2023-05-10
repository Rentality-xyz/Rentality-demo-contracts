import HostNavbar from "../../components/host/HostNavbar";
import { useParams } from "react-router-dom";
import RentCarJSON from "../../abis";
import axios from "axios";
import { useState } from "react";

export default function CarInfo(props) {
  const [dataFetched, setDataFetched] = useState(false);
  const [carInfo, setCarInfo] = useState({});
  const [userWeb3Address, setUserWeb3Address] = useState("0x");

  const getCarData = async (tokenId) => {
    const ethers = require("ethers");
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const addr = await signer.getAddress();
    let contract = new ethers.Contract(
      RentCarJSON.address,
      RentCarJSON.abi,
      signer
    );

    const tokenURI = await contract.tokenURI(tokenId);
    const listedToken = await contract.getCarToRentForId(tokenId);
    let price = listedToken.pricePerDayInUsdCents / 100;
    let meta = await axios.get(tokenURI, {
      headers: {
        'Accept': 'application/json',
      }
    });
    meta = meta.data;

    let item = {
      tokenId: tokenId,
      owner: listedToken.owner,
      image: meta.image,
      name: meta.name,
      description: meta.description,
      price: price,
      vinNumber: meta.attributes?.find((x) => x.trait_type === "VIN number")?.value,
      licensePlate: meta.attributes?.find((x) => x.trait_type === "License plate")?.value,
      state: meta.attributes?.find((x) => x.trait_type === "State")?.value,
      brand: meta.attributes?.find((x) => x.trait_type === "Brand")?.value,
      model: meta.attributes?.find((x) => x.trait_type === "Model")?.value,
      releaseYear: meta.attributes?.find((x) => x.trait_type === "Release year")?.value,
      bodyType: meta.attributes?.find((x) => x.trait_type === "Body type")?.value,
      color: meta.attributes?.find((x) => x.trait_type === "Color")?.value,
      doorsNumber: meta.attributes?.find((x) => x.trait_type === "Number of doors")?.value,
      seatsNumber: meta.attributes?.find((x) => x.trait_type === "Number of seats")?.value,
      trunkSize: meta.attributes?.find((x) => x.trait_type === "Trunk size")?.value,
      transmission: meta.attributes?.find((x) => x.trait_type === "Transmission")?.value,
      wheelDrive: meta.attributes?.find((x) => x.trait_type === "Wheel drive")?.value,
      fuelType: meta.attributes?.find((x) => x.trait_type === "Fuel type")?.value,
      tankVolumeInGal: meta.attributes?.find((x) => x.trait_type === "Tank volume(gal)")?.value,
      distanceIncludedInMi: meta.attributes?.find((x) => x.trait_type === "Distance included(mi)")?.value,
    };
    //console.log(item);
    setCarInfo(item);
    setDataFetched(true);
    setUserWeb3Address(addr);
  };

  const params = useParams();
  const tokenId = params.tokenId;
  if (!dataFetched) getCarData(tokenId);

  return (
    <div style={{ "min-height": "100vh" }}>
      <HostNavbar></HostNavbar>
      <div className="flex ml-20 mt-20">
        <div className="w-2/5">
          <img src={carInfo.image} alt="" className="w-full" />
        </div>
        <div className="text-xl ml-20 space-y-8 text-white shadow-2xl rounded-lg border-2 p-5">
          <div>Name: {carInfo.name}</div>
          <div>Model: {carInfo.model}</div>
          <div>Description: {carInfo.description}</div>
          <div>VIN number: {carInfo.vinNumber}</div>
          <div>License plate: {carInfo.licensePlate}</div>
          <div>State: {carInfo.state}</div>
          <div>Brand: {carInfo.brand}</div>
          <div>Model: {carInfo.model}</div>
          <div>Release year: {carInfo.releaseYear}</div>
          <div>Body type: {carInfo.bodyType}</div>
          <div>Color: {carInfo.color}</div>
          <div>Number of doors: {carInfo.doorsNumber}</div>
          <div>Number of seats: {carInfo.seatsNumber}</div>
          <div>Trunk size: {carInfo.trunkSize}</div>
          <div>Transmission: {carInfo.transmission}</div>
          <div>Wheel drive: {carInfo.wheelDrive}</div>
          <div>Fuel type: {carInfo.fuelType}</div>
          <div>Tank volume(gal): {carInfo.tankVolumeInGal}</div>
          <div>Distance included(mi): {carInfo.distanceIncludedInMi}</div>
          <div>
            Price per day: <span className="">{"$" + carInfo.price}</span>
          </div>
          <div>
            Owner: <span className="text-sm">{carInfo.owner}</span>
          </div>
          {userWeb3Address === carInfo.owner ? (
            <div className="text-emerald-700">
              You are the owner of this car
            </div>
          ) : (
            <div />
          )}
        </div>
      </div>
    </div>
  );
}
