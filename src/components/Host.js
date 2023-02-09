import Navbar from "./Navbar";
import CarTile from "./CarTile";
import RentCarJSON from "../RentCar.json";
import axios from "axios";
import { useState } from "react";

export default function Host() {
const [data, updateData] = useState([]);
const [dataFetched, updateFetched] = useState(false);

async function getMyCars() {
    const ethers = require("ethers");
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    let contract = new ethers.Contract(RentCarJSON.address, RentCarJSON.abi, signer)
    
    let transaction = await contract.getMyCars()

    //Fetch all the details of every NFT from the contract and display
    const items = await Promise.all(transaction.map(async i => {
        const tokenURI = await contract.tokenURI(i.tokenId);
        let meta = await axios.get(tokenURI);
        meta = meta.data;

        let price = ethers.utils.formatUnits(i.pricePerDay.toString(), 'ether');
        
        let item = {
            price,
            tokenId: i.tokenId.toNumber(),
            image: meta.image,
            name: meta.name,
            model: meta.model,
            description: meta.description,
        }
        return item;
    }))

    updateFetched(true);
    updateData(items);
}

if(!dataFetched)
    getMyCars();

return (
    <div>
        <Navbar></Navbar>
        <div className="flex flex-col place-items-center mt-20">
            <div className="md:text-xl font-bold text-white">
                My Cars
            </div>
            <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
                {(data != null && data.length  > 0)?                
                    data.map((value, index) => {
                        return <CarTile data={value} key={index}></CarTile>;
                    })
                    :
                    <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">You dont have listed cars</div>
                }                
            </div>
        </div>            
    </div>
);

}