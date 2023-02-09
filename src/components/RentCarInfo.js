import Navbar from "./Navbar";
import { useLocation, useParams } from 'react-router-dom';
import RentCarJSON from "../RentCar.json";
import axios from "axios";
import { useState } from "react";

export default function RentCarInfo (props) {

const [data, updateData] = useState({});
const [days, updateDays] = useState(1);
const [totalPrice, updateTotalPrice] = useState(0);
const [dataFetched, updateDataFetched] = useState(false);
const [message, updateMessage] = useState("");
const [currAddress, updateCurrAddress] = useState("0x");

function updateRentForDays(value){
    updateDays(value);
    updateTotalPrice(value * data.price);
}

async function getCarData(tokenId) {
    const ethers = require("ethers");
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const addr = await signer.getAddress();
    let contract = new ethers.Contract(RentCarJSON.address, RentCarJSON.abi, signer)
    
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
    updateDays(1);
    updateTotalPrice(price);
    updateDataFetched(true);
    console.log("address", addr)
    updateCurrAddress(addr);
}

async function rentCar(tokenId) {
    try {
        const ethers = require("ethers");
        //After adding your Hardhat network to your metamask, this code will get providers and signers
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();

        //Pull the deployed contract instance
        let contract = new ethers.Contract(RentCarJSON.address, RentCarJSON.abi, signer);
        const rentPrice = ethers.utils.parseUnits(totalPrice.toString(), 'ether')
        updateMessage("Buying the NFT... Please Wait (Upto 5 mins)")
        //run the executeSale function
        let transaction = await contract.rentCar(tokenId, days, {value:rentPrice});
        await transaction.wait();

        alert('You successfully rent this car!');
        updateMessage("");
    }
    catch(e) {
        alert("Upload Error"+e)
    }
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
                        Rent for <input className="shadow appearance-none border rounded w-1/5 py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline" type="number" placeholder="Min 1 day" step="1" value={days} onChange={e => updateRentForDays(e.target.value)}></input> days
                    </div>
                    <div>
                        Total Price: <span className="">{totalPrice + " ETH"}</span>
                    </div>
                    <div>
                    <button className="enableEthereumButton bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm" onClick={() => rentCar(tokenId)}>Rent this car</button>
                    
                    <div className="text-green text-center mt-3">{message}</div>
                    </div>
                </div>
            </div>
        </div>
    )
}