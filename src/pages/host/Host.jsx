import HostNavbar from "../../components/host/HostNavbar";
import CarTile from "../../components/CarTile";
import RequestTile from "../../components/RequestTile";
import RentCarJSON from "../../abis";
import axios from "axios";
import { useState } from "react";

export default function Host() {
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

      const myCars = await Promise.all(
        myCarsTransaction.map(async (i) => {
          const tokenURI = await contract.tokenURI(i.tokenId);
          let meta = await axios.get(tokenURI, {
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Headers':'Access-Control-Allow-Headers, Origin,Accept, X-Requested-With, Content-Type, Access-Control-Request-Method, Access-Control-Request-Headers'
            }
          });
          meta = meta.data;
          let price = i.pricePerDayInUsdCents / 100;

          let item = {
            tokenId: i.tokenId.toNumber(),
            owner: i.owner.toString(),
            price,
            image: meta.image,
            name: meta.name,
            description: meta.description,
            brand: meta.attributes?.find((x) => x.trait_type === "Brand")?.value ?? "",
            model: meta.attributes?.find((x) => x.trait_type === "Model")?.value ?? "",
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

  const approveRentCarRequest = async (carRequest) => {
    try {
      const ethers = require("ethers");
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      let contract = new ethers.Contract(
        RentCarJSON.address,
        RentCarJSON.abi,
        signer
      );

      let transaction = await contract.approveRentCar(carRequest.tokenId);
      await transaction.wait();

      alert("Car rent approved!");
      window.location.replace("/");
    } catch (e) {
      alert("approveRentCar error" + e);
    }
  };

  const rejectRentCarRequest = async (carRequest) => {
    try {
      const ethers = require("ethers");
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      let contract = new ethers.Contract(
        RentCarJSON.address,
        RentCarJSON.abi,
        signer
      );

      let transaction = await contract.rejectRentCar(carRequest.tokenId);
      await transaction.wait();

      alert("Car rent rejected!");
      window.location.replace("/");
    } catch (e) {
      alert("rejectRentCar error" + e);
    }
  };

  if (!dataFetched) getMyCars();

  return (
    <div>
      <HostNavbar></HostNavbar>
      <div className="flex flex-row mt-20 text-white">
        <div className="flex flex-col w-2/3 place-items-center">
          <div className="md:text-xl font-bold">My Cars</div>
          <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
            {hostCars != null && hostCars.length > 0 ? (
              hostCars.map((value, index) => {
                return <CarTile key={index} carInfo={value}></CarTile>;
              })
            ) : (
              <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
                You dont have listed cars
              </div>
            )}
          </div>
        </div>
        <div className="flex flex-col w-1/3 place-items-center">
          <div className="md:text-xl font-bold">My requests</div>
          <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
            {hostRequests != null && hostRequests.length > 0 ? (
              hostRequests.map((value, index) => {
                return (
                  <RequestTile
                    key={index}
                    requestInfo={value}
                    onApprove={approveRentCarRequest}
                    onReject={rejectRentCarRequest}
                  ></RequestTile>
                );
              })
            ) : (
              <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center ">
                You dont have requests
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
