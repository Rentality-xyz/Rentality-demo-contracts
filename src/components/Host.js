import Navbar from "./Navbar";
import CarTile from "./CarTile";
import RequestTile from "./RequestTile";
import RentCarJSON from "../ContractExport";
import axios from "axios";
import { useState } from "react";

export default function Host() {
const [data, updateData] = useState([]);
const [requests, updateRequests] = useState([]);
const [dataFetched, updateFetched] = useState(false);

async function getMyCars() {
    const ethers = require("ethers");
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    let contract = new ethers.Contract(RentCarJSON.address, RentCarJSON.abi, signer)
    
    try {
        let myCarsTransaction = await contract.getMyCars()
    
        //Fetch all the details of every NFT from the contract and display
        const myCars = await Promise.all(myCarsTransaction.map(async i => {
            const tokenURI = await contract.tokenURI(i.tokenId);
            let meta = await axios.get(tokenURI);
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
            }
            return item;
        }))

        updateData(myCars);
    }
    catch(e) {
        console.log( "get myCars error"+e )
    }

    try {
        let myRequeststransaction = await contract.getRequestsForMyCars()
    
        //Fetch all the details of every NFT from the contract and display
        const myRequests = await Promise.all(myRequeststransaction.map(async i => {
            const tokenURI = await contract.tokenURI(i.tokenId);
            let meta = await axios.get(tokenURI);
            meta = meta.data;
    
            let totalPrice = ethers.utils.formatUnits(i.totalPrice.toString(), 'ether');
            
            let item = {
                tokenId: i.tokenId.toNumber(),
                renter: i.renter.toString(),
                daysForRent: i.daysForRent.toString(),
                totalPrice,
                image: meta.image,
                name: meta.name,
                model: meta.model,
            }
            return item;
        }))
        
        updateRequests(myRequests);
    }
    catch(e) {
        console.log( "get myRequests error"+e )
    }

    updateFetched(true);
}

if(!dataFetched)
    getMyCars();

return (
    <div>
        <Navbar></Navbar>
        <div className="flex flex-row mt-20">
            <div className="flex flex-col w-2/3 place-items-center">
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
            <div className="flex flex-col w-1/3 place-items-center">
                <div className="md:text-xl font-bold text-white">
                    My requests
                </div>
                <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">
                    {(requests != null && requests.length  > 0)?                
                        requests.map((value, index) => {
                            return <RequestTile data={value} key={index}></RequestTile>;
                        })
                        :
                        <div className="flex mt-5 justify-between flex-wrap max-w-screen-xl text-center">You dont have requests</div>
                    }                
                </div>
            </div>
        </div>            
    </div>
);

}