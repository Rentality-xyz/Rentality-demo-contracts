import Navbar from "./Navbar";
import {useParams } from 'react-router-dom';
import RentCarJSON from "../RentCar.json";
import axios from "axios";
import { useState } from "react";

export default function CarInfo (props) {

const [data, updateData] = useState({});
const [dataFetched, updateDataFetched] = useState(false);
const [currAddress, updateCurrAddress] = useState("0x");

async function getCarData(tokenId) {
    const ethers = require("ethers");
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const addr = await signer.getAddress();
    let contract = new ethers.Contract(RentCarJSON.address, RentCarJSON.abi, signer)
    
    //create an NFT Token
    const tokenURI = await contract.tokenURI(tokenId);
    const listedToken = await contract.getCarToRentForId(tokenId);
    let price = ethers.utils.formatUnits(listedToken.pricePerDay.toString(), 'ether');
    let meta = await axios.get(tokenURI);
    meta = meta.data;
    console.log(listedToken);

    let item = {
        price: price,
        tokenId: tokenId,
        owner: listedToken.owner,
        image: meta.image,
        name: meta.name,
        model: meta.model,
        description: meta.description,
    }
    console.log(item);
    updateData(item);
    updateDataFetched(true);
    console.log("address", addr)
    updateCurrAddress(addr);
}

    const params = useParams();
    const tokenId = params.tokenId;
    if(!dataFetched)
        getCarData(tokenId);

    return(
        <div style={{"min-height":"100vh"}}>
            <Navbar></Navbar>
            <div className="flex ml-20 mt-20">
                <img src={data.image} alt="" className="w-2/5" />
                <div className="text-xl ml-20 space-y-8 text-white shadow-2xl rounded-lg border-2 p-5">
                    <div>
                        Name: {data.name}
                    </div>
                    <div>
                        Model: {data.model}
                    </div>
                    <div>
                        Description: {data.description}
                    </div>
                    <div>
                        Price: <span className="">{data.price + " ETH"}</span>
                    </div>
                    <div>
                        Owner: <span className="text-sm">{data.owner}</span>
                    </div>
                    <div>
                        <div className="text-emerald-700">You are the owner of this car</div>
                    </div>
                </div>
            </div>
        </div>
    )
}