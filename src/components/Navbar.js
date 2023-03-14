import fullLogo from "../full_logo.png";
import { Link } from "react-router-dom";
import { useEffect, useState, useRef } from "react";
import { useLocation } from "react-router";
import RentCarJSON from "../ContractExport";

export default function Navbar() {
  const [userConnected, setUserConnected] = useState(false);
  const [userWeb3Address, setUserWeb3Address] = useState("0x");
  const location = useLocation();
  const connectButtonRef = useRef();
  const withdrawTipsButtonRef = useRef();

  const getAddress = async () => {
    const ethers = require("ethers");
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const address = await signer.getAddress();
    setUserWeb3Address(address);
  };

  const updateButton = () => {
    connectButtonRef.current.textContent = "Connected";
    connectButtonRef.current.classList.remove("hover:bg-blue-70");
    connectButtonRef.current.classList.remove("bg-blue-500");
    connectButtonRef.current.classList.add("hover:bg-green-70");
    connectButtonRef.current.classList.add("bg-green-500");
  };

  const isHost = () => {
    return (
      location.pathname === "/host" ||
      location.pathname === "/addCar" ||
      location.pathname.substring(0, 8) === "/carInfo"
    );
  };

  const connectWebsite = async () => {
    const chainId = await window.ethereum.request({ method: "eth_chainId" });
    if (chainId !== "0x5") {
      //alert('Incorrect network! Switch your metamask network to Rinkeby');
      await window.ethereum.request({
        method: "wallet_switchEthereumChain",
        params: [{ chainId: "0x5" }],
      });
    }
    await window.ethereum
      .request({ method: "eth_requestAccounts" })
      .then(() => {
        updateButton();
        console.log("here");
        getAddress();
        window.location.replace(location.pathname);
      });
  };

  const formatAddress = (address) => {
    if (address == null || address.length < 16) return address;
    return address.substr(0, 6) + ".." + address.substr(address.length - 8);
  };

  const withdrawTips = async () => {
    try {
      const ethers = require("ethers");
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();

      let contract = new ethers.Contract(
        RentCarJSON.address,
        RentCarJSON.abi,
        signer
      );

      withdrawTipsButtonRef.current.disabled = true;

      let transaction = await contract.withdrawTips();
      await transaction.wait();

      alert("You successfully withdraw tips!");
      withdrawTipsButtonRef.current.disabled = false;
    } catch (e) {
      alert("withdrawTips error:" + e);
      withdrawTipsButtonRef.current.disabled = false;
    }
  };

  const handleAccountsChanged = () => {
    window.location.replace("/");
  };

  useEffect(() => {
    let isConnected = window.ethereum.isConnected();
    if (isConnected) {
      console.log("web3 user is connected");
      getAddress();
      setUserConnected(isConnected);
      updateButton();
    }

    window.ethereum.on("accountsChanged", handleAccountsChanged);

    return () => {
      window.ethereum.removeListener("accountsChanged", handleAccountsChanged);
    };
  });

  return (
    <div className="flex flex-col pt-2">
      <nav className="w-screen">
        <ul className="flex items-end justify-between bg-transparent text-white py-3 pr-5">
          <li className="flex items-end ml-5 pb-2">
            <Link to="/">
              <img
                src={fullLogo}
                alt=""
                width={150}
                height={150}
                className="inline-block -mt-2"
              />
              <div className="inline-block font-bold text-2xl ml-6">
                Rentality v0.1
              </div>
            </Link>
          </li>
          <li className="w-2/6">
            <ul className="lg:flex justify-between font-bold mr-10 text-lg">
              {isHost() ? (
                <li>
                  <Link to="/guest">
                    <button className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm">
                      Switch to Guest
                    </button>
                  </Link>
                </li>
              ) : (
                <li>
                  <Link to="/host">
                    <button className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm">
                      Switch to Host
                    </button>
                  </Link>
                </li>
              )}
              {isHost() ? (
                location.pathname === "/host" ? (
                  <li className="border-b-2 p-2 pb-0">
                    <Link to="/host">Main</Link>
                  </li>
                ) : (
                  <li className="hover:border-b-2 p-2 pb-0">
                    <Link to="/host">Main</Link>
                  </li>
                )
              ) : location.pathname === "/guest" ? (
                <li className="border-b-2 p-2 pb-0">
                  <Link to="/guest">Main</Link>
                </li>
              ) : (
                <li className="hover:border-b-2 p-2 pb-0">
                  <Link to="/guest">Main</Link>
                </li>
              )}
              {isHost() ? (
                location.pathname === "/addCar" ? (
                  <li className="border-b-2 p-2 pb-0">
                    <Link to="/addCar">List Car</Link>
                  </li>
                ) : (
                  <li className="hover:border-b-2 p-2 pb-0">
                    <Link to="/addCar">List Car</Link>
                  </li>
                )
              ) : location.pathname === "/rentCar" ? (
                <li className="border-b-2 p-2 pb-0">
                  <Link to="/rentCar">Rent Car</Link>
                </li>
              ) : (
                <li className="hover:border-b-2 p-2 pb-0">
                  <Link to="/rentCar">Rent Car</Link>
                </li>
              )}
              {/* {location.pathname === "/profile" ? 
              <li className='border-b-2 p-2 pb-0'>
                <Link to="/profile">Profile</Link>
              </li>
              :
              <li className='hover:border-b-2 p-2 pb-0'>
                <Link to="/profile">Profile</Link>
              </li>              
              } */}
              <li>
                <button
                  ref={withdrawTipsButtonRef}
                  className="withdrawButton hidden bg-blue-500 hover:bg-blue-700 disabled:bg-gray-500 text-white font-bold py-2 px-4 mx-4 rounded text-sm"
                  onClick={withdrawTips}
                >
                  Withdraw Tips
                </button>
              </li>
              <li>
                <button
                  ref={connectButtonRef}
                  className="enableEthereumButton bg-blue-500 hover:bg-blue-700 disabled:bg-gray-500 text-white font-bold py-2 px-4 rounded text-sm"
                  onClick={connectWebsite}
                >
                  {userConnected ? "Connected" : "Connect Wallet"}
                </button>
              </li>
            </ul>
          </li>
        </ul>
      </nav>
      <div className="text-white text-bold text-right mr-10 text-sm">
        {userWeb3Address !== "0x"
          ? "Connected to " + formatAddress(userWeb3Address)
          : "Not Connected. Please login using Metamask"}
      </div>
    </div>
  );
}
