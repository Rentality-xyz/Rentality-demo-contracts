import fullLogo from '../full_logo.png';
import { Link } from "react-router-dom";
import { useEffect, useState } from 'react';
import { useLocation } from 'react-router';
import RentCarJSON from "../ContractExport";

function Navbar() {

const [connected, toggleConnect] = useState(false);
const location = useLocation();
const [currAddress, updateAddress] = useState('0x');

async function getAddress() {
  const ethers = require("ethers");
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const signer = provider.getSigner();
  const addr = await signer.getAddress();
  updateAddress(addr);
}

function updateButton() {
  const ethereumButton = document.querySelector('.enableEthereumButton');
  ethereumButton.textContent = "Connected";
  ethereumButton.classList.remove("hover:bg-blue-70");
  ethereumButton.classList.remove("bg-blue-500");
  ethereumButton.classList.add("hover:bg-green-70");
  ethereumButton.classList.add("bg-green-500");
}

function isHost() {
  return location.pathname === "/host" || location.pathname === "/addCar" || location.pathname.substring(0,8) === "/carInfo";
}

async function connectWebsite() {

    const chainId = await window.ethereum.request({ method: 'eth_chainId' });
    if(chainId !== '0x5')
    {
      //alert('Incorrect network! Switch your metamask network to Rinkeby');
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: '0x5' }],
     })
    }  
    await window.ethereum.request({ method: 'eth_requestAccounts' })
      .then(() => {
        updateButton();
        console.log("here");
        getAddress();
        window.location.replace(location.pathname)
      });
}

function formatAddress(address) {  
  if (address == null || address.length < 10) 
      return address;
  return address.substr(0,6) + ".." + address.substr(address.length - 8);
}

async function withdrawTips() {
  try {
      const ethers = require("ethers");
      //After adding your Hardhat network to your metamask, this code will get providers and signers
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();

      //Pull the deployed contract instance
      let contract = new ethers.Contract(RentCarJSON.address, RentCarJSON.abi, signer);
      const saveButton = document.querySelector('.saveButton');
      saveButton.disabled = true;
      //run the executeSale function
      let transaction = await contract.withdrawTips();
      await transaction.wait();

      alert('You successfully withdraw Tips!');
      saveButton.disabled = false;
  }
  catch(e) {
      alert("Upload Error"+e)
  }
}

  useEffect(() => {
    let val = window.ethereum.isConnected();
    if(val)
    {
      console.log("here");
      getAddress();
      toggleConnect(val);
      updateButton();
    }

    window.ethereum.on('accountsChanged', function(accounts){
      window.location.replace(location.pathname)
    })
  });

    return (
      <div className="">
        <nav className="w-screen">
          <ul className='flex items-end justify-between py-3 bg-transparent text-white pr-5'>
          <li className='flex items-end ml-5 pb-2'>
            <Link to="/">
            <img src={fullLogo} alt="" width={150} height={150} className="inline-block -mt-2"/>
            <div className='inline-block font-bold text-xl ml-4'>
              Rentality v0.1
            </div>
            </Link>
          </li>
          <li className='w-2/6'>
            <ul className='lg:flex justify-between font-bold mr-10 text-lg'>
              {(isHost() )? 
              <li>
                <Link to="/guest">
                  <button className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm">Switch to Guest</button>
                </Link>
              </li>              
              :
              <li>
                <Link to="/host">
                  <button className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm">Switch to Host</button>
                </Link>
              </li>               
              }
              {(isHost())? 
              location.pathname === "/host"?
              <li className='border-b-2 p-2 pb-0'>
                <Link to="/host">Main</Link> 
              </li>
              :
              <li className='hover:border-b-2 p-2 pb-0'>
                <Link to="/host">Main</Link>
              </li>  
              :
              location.pathname === "/guest"?
              <li className='border-b-2 p-2 pb-0'>
                <Link to="/guest">Main</Link>
              </li>
              :
              <li className='hover:border-b-2 p-2 pb-0'>
                <Link to="/guest">Main</Link>
              </li>          
              } 
              {(isHost() )? 
              location.pathname === "/addCar"?
              <li className='border-b-2 p-2 pb-0'>
                <Link to="/addCar">List Car</Link>
              </li>
              :
              <li className='hover:border-b-2 p-2 pb-0'>
                <Link to="/addCar">List Car</Link>
              </li>  
              :
              location.pathname === "/rentCar"?
              <li className='border-b-2 p-2 pb-0'>
                <Link to="/rentCar">Rent Car</Link>
              </li>
              :
              <li className='hover:border-b-2 p-2 pb-0'>
                <Link to="/rentCar">Rent Car</Link>
              </li>          
              }  
              {/* {location.pathname === "/profile" ? 
              <li className='border-b-2 p-2 pb-0'>
                <Link to="/profile">Profile</Link>
              </li>
              :
              <li className='hover:border-b-2 p-2 pb-0'>
                <Link to="/profile">Profile</Link>
              </li>              
              }
              <li>
                <button className="withdrawButton bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 mx-4 rounded text-sm" onClick={withdrawTips}>{"Withdraw Tips"}</button>
              </li> */}
              <li>
                <button className="enableEthereumButton bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm" onClick={connectWebsite}>{connected? "Connected":"Connect Wallet"}</button>
              </li>
            </ul>
          </li>
          </ul>
        </nav>
        <div className='text-white text-bold text-right mr-10 text-sm'>
          {currAddress !== "0x" ? "Connected to":"Not Connected. Please login to view NFTs"} {currAddress !== "0x" ? (formatAddress(currAddress)):""}
        </div>
      </div>
    );
  }

  export default Navbar;