import Navbar from "./Navbar";
import { useState } from "react";
import { uploadFileToIPFS, uploadJSONToIPFS } from "../pinata";
import RentCarJSON from "../ContractExport";

const AddCar = () => {
  const [carInfoFormParams, setCarInfoFormParams] = useState({
    name: "",
    model: "",
    description: "",
    price: "",
  });
  const [fileURL, setFileURL] = useState(null);
  const ethers = require("ethers");
  const [message, setMessage] = useState("");

  //This function uploads the car image to IPFS
  const onChangeFile = async (e) => {
    var file = e.target.files[0];
    //check for file extension
    var resizedImage = await resizeImageToSquare(file);
    try {
      //upload the file to IPFS
      const response = await uploadFileToIPFS(resizedImage);
      if (response.success === true) {
        console.log("Uploaded image to Pinata: ", response.pinataURL);
        setFileURL(response.pinataURL);
      }
    } catch (e) {
      console.log("Error during file upload", e);
      alert("Error during file upload: " + e);
    }
  };

  const resizeImageToSquare = async (file) => {
    return new Promise((resolve, reject) => {
      const canvas = document.createElement("canvas");
      const ctx = canvas.getContext("2d");
      const img = new Image();
      img.src = URL.createObjectURL(file);

      img.onload = () => {
        const size = 1000;
        canvas.width = size;
        canvas.height = size;
        ctx.fillStyle = "transparent";
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        const scaleFactor = size / Math.max(img.width, img.height);
        const scaledWidth = img.width * scaleFactor;
        const scaledHeight = img.height * scaleFactor;
        ctx.drawImage(
          img,
          (size - scaledWidth) / 2,
          (size - scaledHeight) / 2,
          scaledWidth,
          scaledHeight
        );
        canvas.toBlob(
          (blob) => {
            const resizedFile = new File([blob], file.name, {
              type: "image/png",
            });
            resolve(resizedFile);
          },
          "image/png",
          1
        );
      };

      img.onerror = reject;
    });
  };

  //This function uploads the metadata to IPDS
  const uploadMetadataToIPFS = async () => {
    const { name, model, description, price } = carInfoFormParams;
    //Make sure that none of the fields are empty
    if (!name || !model || !description || !price || !fileURL) return;

    const nftJSON = {
      name,
      model,
      description,
      price,
      image: fileURL,
    };

    try {
      //upload the metadata JSON to IPFS
      const response = await uploadJSONToIPFS(nftJSON);
      if (response.success === true) {
        return response.pinataURL;
      }
    } catch (e) {
      console.log("error uploading JSON metadata:", e);
      alert("error uploading JSON metadata: " + e);
    }
  };

  const listCar = async (e) => {
    e.preventDefault();

    //Upload data to IPFS
    try {
      const metadataURL = await uploadMetadataToIPFS();
      //After adding your Hardhat network to your metamask, this code will get providers and signers
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      setMessage("Please wait.. uploading (upto 5 mins)");

      //Pull the deployed contract instance
      let contract = new ethers.Contract(
        RentCarJSON.address,
        RentCarJSON.abi,
        signer
      );

      var doubleNumber = Number(
        carInfoFormParams.price.replace(/[^0-9\.]+/g, "")
      );
      let price = ((doubleNumber * 100) | 0).toString();
      //actually create the NFT
      let transaction = await contract.addCar(metadataURL, price);
      await transaction.wait();

      alert("Successfully listed your car!");
      setMessage("");
      setCarInfoFormParams({ name: "", model: "", description: "", price: "" });
      window.location.replace("/");
    } catch (e) {
      alert("Upload error" + e);
    }
  };

  return (
    <div className="">
      <Navbar></Navbar>
      <div className="flex flex-col place-items-center mt-10" id="nftForm">
        <form className="bg-white shadow-md rounded px-8 pt-4 pb-8 mb-4">
          <h3 className="text-center font-bold text-purple-500 mb-8">
            Upload your car to Rentality
          </h3>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="name"
            >
              Car pet name
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="name"
              type="text"
              placeholder="e.g. Eleanor"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  name: e.target.value,
                })
              }
              value={carInfoFormParams.name}
            ></input>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="model"
            >
              Car model
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="name"
              type="text"
              placeholder="e.g. Shelby Mustang GT500"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  model: e.target.value,
                })
              }
              value={carInfoFormParams.model}
            ></input>
          </div>
          <div className="mb-6">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="description"
            >
              Car description
            </label>
            <textarea
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              cols="40"
              rows="5"
              id="description"
              type="text"
              placeholder="e.g. Dupont Pepper Grey 1967 Ford Mustang fastback"
              value={carInfoFormParams.description}
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  description: e.target.value,
                })
              }
            ></textarea>
          </div>
          <div className="mb-6">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="price"
            >
              Price per day (in USD)
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              type="number"
              placeholder="e.g. 100"
              step="1"
              value={carInfoFormParams.price}
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  price: e.target.value,
                })
              }
            ></input>
          </div>
          <div>
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="image"
            >
              Upload Image
            </label>
            <input type={"file"} onChange={onChangeFile}></input>
          </div>
          <br></br>
          <div className="text-green text-center">{message}</div>
          <button
            onClick={listCar}
            className="font-bold mt-10 w-full bg-purple-500 text-white rounded p-2 shadow-lg"
          >
            List car
          </button>
        </form>
      </div>
    </div>
  );
};

export default AddCar;
