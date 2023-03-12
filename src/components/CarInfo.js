import Navbar from "./Navbar";
import { useParams } from "react-router-dom";
import RentCarJSON from "../ContractExport";
import axios from "axios";
import { useState } from "react";

const CarInfo = (props) => {
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
    let meta = await axios.get(tokenURI);
    meta = meta.data;

    let item = {
      price: price,
      tokenId: tokenId,
      owner: listedToken.owner,
      image: meta.image,
      name: meta.name,
      model: meta.model,
      description: meta.description,
    };
    console.log(item);
    setCarInfo(item);
    setDataFetched(true);
    setUserWeb3Address(addr);
  };

  const params = useParams();
  const tokenId = params.tokenId;
  if (!dataFetched) getCarData(tokenId);

  return (
    <div style={{ "min-height": "100vh" }}>
      <Navbar></Navbar>
      <div className="flex ml-20 mt-20">
        <img src={carInfo.image} alt="" className="w-2/5" />
        <div className="text-xl ml-20 space-y-8 text-white shadow-2xl rounded-lg border-2 p-5">
          <div>Name: {carInfo.name}</div>
          <div>Model: {carInfo.model}</div>
          <div>Description: {carInfo.description}</div>
          <div>
            Price per day: <span className="">{"$" + carInfo.price}</span>
          </div>
          <div>
            Owner: <span className="text-sm">{carInfo.owner}</span>
          </div>
          {userWeb3Address == carInfo.owner ? (
            <div className="text-emerald-700">
              You are the owner of this NFT
            </div>
          ) : (
            <div />
          )}
        </div>
      </div>
    </div>
  );
};

export default CarInfo;
