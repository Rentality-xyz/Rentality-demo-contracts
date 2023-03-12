import Navbar from "./Navbar";
import CarTile from "./CarTile";
import RequestTile from "./RequestTile";
import RentCarJSON from "../ContractExport";
import axios from "axios";
import { useState } from "react";

const Host = () => {
  const [dataFetched, setDataFetched] = useState(false);
  const [hostCars, setHostCars] = useState([]);
  const [hostRequests, setHostRequests] = useState([]);

  const getMyCars = async () => {
    const ethers = require("ethers");
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    let contract = new ethers.Contract(
      RentCarJSON.address,
      RentCarJSON.abi,
      signer
    );

    try {
      let myCarsTransaction = await contract.getMyCars();

      //Fetch all the details of every NFT from the contract and display
      const myCars = await Promise.all(
        myCarsTransaction.map(async (i) => {
          const tokenURI = await contract.tokenURI(i.tokenId);
          console.log("before  axios.get(tokenURI));");
          let meta = await axios.get(tokenURI);
          console.log("after  axios.get(tokenURI));");
          meta = meta.data;
          let price = i.pricePerDayInUsdCents / 100;

          let item = {
            tokenId: i.tokenId.toNumber(),
            owner: i.owner.toString(),
            price,
            image: meta.image,
            name: meta.name,
            model: meta.model,
            description: meta.description,
          };
          return item;
        })
      );

      setHostCars(myCars);
    } catch (e) {
      console.log("get myCars error" + e);
    }

    try {
      let myRequestsTransaction = await contract.getRequestsForMyCars();

      const myRequests = await Promise.all(
        myRequestsTransaction.map(async (i) => {
          const tokenURI = await contract.tokenURI(i.tokenId);
          let meta = await axios.get(tokenURI);
          meta = meta.data;

          let totalPrice = i.totalPrice / 100;

          let item = {
            tokenId: i.tokenId.toNumber(),
            renter: i.renter.toString(),
            daysForRent: i.daysForRent.toString(),
            totalPrice,
            image: meta.image,
            name: meta.name,
            model: meta.model,
          };
          return item;
        })
      );

      setHostRequests(myRequests);
    } catch (e) {
      console.log("get myRequests error" + e);
    }

    setDataFetched(true);
  };

  if (!dataFetched) getMyCars();

  return (
    <div>
      <Navbar></Navbar>
      <div className="flex flex-row mt-20">
        <div className="flex flex-col w-2/3 place-items-center">
          <div className="md:text-xl font-bold text-white">My Cars</div>
          <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
            {hostCars != null && hostCars.length > 0 ? (
              hostCars.map((value, index) => {
                return <CarTile data={value} key={index}></CarTile>;
              })
            ) : (
              <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
                You dont have listed cars
              </div>
            )}
          </div>
        </div>
        <div className="flex flex-col w-1/3 place-items-center">
          <div className="md:text-xl font-bold text-white">My requests</div>
          <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
            {hostRequests != null && hostRequests.length > 0 ? (
              hostRequests.map((value, index) => {
                return <RequestTile data={value} key={index}></RequestTile>;
              })
            ) : (
              <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
                You dont have requests
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Host;
