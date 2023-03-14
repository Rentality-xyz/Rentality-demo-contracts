import Navbar from "../../components/Navbar";
import CarTile from "../../components/CarTile";
import RentCarJSON from "../../ContractExport";
import axios from "axios";
import { useState } from "react";

const Guest = () => {
  const [dataFetched, setDataFetched] = useState(false);
  const [guestRentedCars, setGuestRentedCars] = useState([]);

  const getCarsRentedByMe = async () => {
    const ethers = require("ethers");
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    let contract = new ethers.Contract(
      RentCarJSON.address,
      RentCarJSON.abi,
      signer
    );

    let transaction = await contract.getCarsRentedByMe();
    
    const items = await Promise.all(
      transaction.map(async (i) => {
        const tokenURI = await contract.tokenURI(i.tokenId);
        let meta = await axios.get(tokenURI);
        meta = meta.data;
        let price = i.pricePerDayInUsdCents / 100;

        let item = {
          price,
          tokenId: i.tokenId.toNumber(),
          image: meta.image,
          name: meta.name,
          model: meta.model,
          description: meta.description,
        };
        return item;
      })
    );

    setDataFetched(true);
    setGuestRentedCars(items);
  };

  if (!dataFetched) getCarsRentedByMe();

  return (
    <div>
      <Navbar></Navbar>
      <div className="flex flex-col place-items-center mt-20">
        <div className="md:text-xl font-bold text-white">My rented car</div>
        <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
          {guestRentedCars != null && guestRentedCars.length > 0 ? (
            guestRentedCars.map((value, index) => {
              return <CarTile data={value} key={index}></CarTile>;
            })
          ) : (
            <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
              You don't have rented cars
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Guest;