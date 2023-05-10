import GuestNavbar from "../../components/guest/GuestNavbar";
import { useParams } from "react-router-dom";
import RentCarJSON from "../../abis";
import axios from "axios";
import { useState, useRef } from "react";

export default function RentCarInfo(props) {
  const [dataFetched, setDataFetched] = useState(false);
  const [carInfo, setCarInfo] = useState({});
  const [daysToRent, setDaysToRent] = useState(1);
  const [totalPrice, updsetTotalPrice] = useState(0);
  const [message, setMessage] = useState("");
  const rentCarButtonRef = useRef();

  function updateRentForDays(value) {
    setDaysToRent(value);
    updsetTotalPrice(value * carInfo.price);
  }

  const getCarData = async (tokenId) => {
    const ethers = require("ethers");
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();

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
      price: price,
      tokenId: tokenId,
      owner: listedToken.owner,
      image: meta.image,
      name: meta.name,
      model: meta.model,
      description: meta.description,
    };
    //console.log(item);
    setCarInfo(item);
    setDaysToRent(1);
    updsetTotalPrice(price);
    setDataFetched(true);
  };

  const sendRentCarRequest = async (tokenId) => {
    try {
      const ethers = require("ethers");
      //After adding your Hardhat network to your metamask, this code will get providers and signers
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();

      //Pull the deployed contract instance
      let contract = new ethers.Contract(
        RentCarJSON.address,
        RentCarJSON.abi,
        signer
      );

      const rentPriceInUsdCents = (totalPrice * 100) | 0;
      const rentPriceInEth = await contract.getEthFromUsd(rentPriceInUsdCents);

      setMessage("Renting the car... Please Wait (Upto 5 mins)");
      rentCarButtonRef.current.disabled = true;
      //run the executeSale function
      let transaction = await contract.rentCar(tokenId, daysToRent, {
        value: rentPriceInEth,
      });
      await transaction.wait();

      alert("You successfully send request to rent this car!");
      setMessage("");
      window.location.replace("/");
    } catch (e) {
      alert("Upload Error" + e);
      rentCarButtonRef.current.disabled = false;
    }
  };

  const params = useParams();
  const tokenId = params.tokenId;
  if (!dataFetched) getCarData(tokenId);

  return (
    <div style={{ "min-height": "100vh" }}>
      <GuestNavbar></GuestNavbar>
      <div className="flex ml-20 mt-20">
        <div className="w-2/5" >
          <img src={carInfo.image} alt="" className="w-full" />
        </div>
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
          <div>
            Rent for{" "}
            <input
              className="shadow appearance-none border rounded w-1/5 py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              type="number"
              placeholder="Min 1 day"
              step="1"
              value={daysToRent}
              onChange={(e) => updateRentForDays(e.target.value)}
            ></input>{" "}
            days
          </div>
          <div>
            Total Price: <span className="">{"$" + totalPrice}</span>
          </div>
          <div>
            <button
              ref={rentCarButtonRef}
              className="saveButton bg-blue-500 hover:bg-blue-700 disabled:bg-gray-500 text-white font-bold py-2 px-4 rounded text-sm"
              onClick={() => sendRentCarRequest(tokenId)}
            >
              Rent this car
            </button>

            <div className="text-green text-center mt-3">{message}</div>
          </div>
        </div>
      </div>
    </div>
  );
}
