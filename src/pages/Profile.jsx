import Navbar from "../components/Navbar";
import { useParams } from "react-router-dom";
import RentCarJSON from "../abis";
import axios from "axios";
import { useState } from "react";
import CarTile from "../components/CarTile";

export default function Profile() {
  const [dataFetched, setDataFetched] = useState(false);
  const [hostCars, setHostCars] = useState([]);
  const [userAddress, setUserAddress] = useState("0x");
  const [totalPrice, setTotalPrice] = useState("0");

  const getNFTData = async (tokenId) => {
    const ethers = require("ethers");
    let sumPrice = 0;
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const addr = await signer.getAddress();

    let contract = new ethers.Contract(
      RentCarJSON.address,
      RentCarJSON.abi,
      signer
    );

    let myCarsTransaction = await contract.getMyCars();

    const items = await Promise.all(
      myCarsTransaction.map(async (i) => {
        const tokenURI = await contract.tokenURI(i.tokenId);
        let meta = await axios.get(tokenURI, {
          headers: {
            'Accept': 'application/json',
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
          model: meta.model,
          description: meta.description,
        };
        sumPrice += Number(price);
        return item;
      })
    );

    setHostCars(items);
    setDataFetched(true);
    setUserAddress(addr);
    setTotalPrice(sumPrice.toPrecision(3));
  };

  const params = useParams();
  const tokenId = params.tokenId;
  if (!dataFetched) getNFTData(tokenId);

  return (
    <div className="profileClass" style={{ "min-height": "100vh" }}>
      <Navbar></Navbar>
      <div className="profileClass">
        <div className="flex text-center flex-col mt-11 md:text-2xl text-white">
          <div className="mb-5">
            <h2 className="font-bold">Wallet Address</h2>
            {userAddress}
          </div>
        </div>
        <div className="flex flex-row text-center justify-center mt-10 md:text-2xl text-white">
          <div>
            <h2 className="font-bold">No. of NFTs</h2>
            {hostCars.length}
          </div>
          <div className="ml-20">
            <h2 className="font-bold">Total Value</h2>$ {totalPrice}
          </div>
        </div>
        <div className="flex flex-col text-center items-center mt-11 text-white">
          <h2 className="font-bold">Your NFTs</h2>
          <div className="flex justify-center flex-wrap max-w-screen-xl">
            {hostCars.map((value, index) => {
              return <CarTile key={index} carInfo={value}></CarTile>;
            })}
          </div>
          <div className="mt-10 text-xl">
            {hostCars.length === 0
              ? "Oops, No NFT data to display (Are you logged in?)"
              : ""}
          </div>
        </div>
      </div>
    </div>
  );
}
