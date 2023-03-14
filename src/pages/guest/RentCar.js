import Navbar from "../../components/Navbar";
import RentedCarTile from "../../components/RentedCarTile";
import RentCarJSON from "../../ContractExport";
import axios from "axios";
import { useState } from "react";

const RentCar = () => {
  const [dataFetched, usetDataFetched] = useState(false);
  const [carsToRent, setCarsToRent] = useState([]);

  const getAllAvailableCars = async () => {
    const ethers = require("ethers");
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    let contract = new ethers.Contract(
      RentCarJSON.address,
      RentCarJSON.abi,
      signer
    );

    let transaction = await contract.getAllAvailableCars();

    const items = await Promise.all(
      transaction.map(async (i) => {
        const tokenURI = await contract.tokenURI(i.tokenId);
        let meta = await axios.get(tokenURI);
        meta = meta.data;
        let price = i.pricePerDayInUsdCents / 100;

        let item = {
          price,
          tokenId: i.tokenId.toNumber(),
          seller: i.seller,
          owner: i.owner,
          image: meta.image,
          name: meta.name,
          model: meta.model,
          description: meta.description,
        };
        return item;
      })
    );

    usetDataFetched(true);
    setCarsToRent(items);
  };

  if (!dataFetched) getAllAvailableCars();

  return (
    <div>
      <Navbar></Navbar>
      <div className="flex flex-col place-items-center mt-20">
        <div className="md:text-xl font-bold text-white">
          Car available to rent
        </div>
        <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
          {carsToRent.map((value, index) => {
            return <RentedCarTile data={value} key={index}></RentedCarTile>;
          })}
        </div>
      </div>
    </div>
  );
};

export default RentCar;
