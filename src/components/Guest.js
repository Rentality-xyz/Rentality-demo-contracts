import Navbar from "./Navbar";
import CarTile from "./CarTile";
import RentCarJSON from "../RentCar.json";
import axios from "axios";
import { useState } from "react";

export default function Guest() {
const [data, updateData] = useState([]);
const [dataFetched, updateFetched] = useState(false);

async function getAllNFTs() {
    const ethers = require("ethers");
    //After adding your Hardhat network to your metamask, this code will get providers and signers
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    //Pull the deployed contract instance
    let contract = new ethers.Contract(RentCarJSON.address, RentCarJSON.abi, signer)
    //create an NFT Token
    let transaction = await contract.getCarsRentedByMe()

    //Fetch all the details of every NFT from the contract and display
    const items = await Promise.all(transaction.map(async i => {
        const tokenURI = await contract.tokenURI(i.tokenId);
        let meta = await axios.get(tokenURI);
        meta = meta.data;

        let price = ethers.utils.formatUnits(i.price.toString(), 'ether');
        let item = {
            price,
            tokenId: i.tokenId.toNumber(),
            seller: i.seller,
            owner: i.owner,
            image: meta.image,
            name: meta.name,
            description: meta.description,
        }
        return item;
    }))

    updateFetched(true);
    updateData(items);
}

if(!dataFetched)
    getAllNFTs();

return (
    <div>
        <Navbar></Navbar>
        <div className="flex flex-col place-items-center mt-20">
            <div className="md:text-xl font-bold text-white">
                My rented car
            </div>
            <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
                {(data != null && data.length  > 0)?                
                    data.map((value, index) => {
                        return <CarTile data={value} key={index}></CarTile>;
                    })
                    :
                    <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">You don't have rented cars</div>
                }
            </div>
        </div>            
    </div>
);

}