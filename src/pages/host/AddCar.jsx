import HostNavbar from "../../components/host/HostNavbar";
import { useState, useRef } from "react";
import { uploadFileToIPFS, uploadJSONToIPFS } from "../../utils/pinata";
import RentCarJSON from "../../abis";

export default function AddCar() {
  const [carInfoFormParams, setCarInfoFormParams] = useState({
    name: "",
    description: "",
    vinNumber: "",
    licensePlate: "",
    state: "",
    brand: "",
    model: "",
    releaseYear: "",
    bodyType: "",
    color: "",
    doorsNumber: "",
    seatsNumber: "",
    trunkSize: "",
    transmission: "",
    wheelDrive: "",
    fuelType: "",
    tankVolumeInGal: "",
    distanceIncludedInMi: "",
    pricePerDay: "",
  });
  const [fileURL, setFileURL] = useState(null);
  const ethers = require("ethers");
  const [message, setMessage] = useState("");
  const listCarButtonRef = useRef();

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
    const {
      name,
      description,
      vinNumber,
      licensePlate,
      state,
      brand,
      model,
      releaseYear,
      bodyType,
      color,
      doorsNumber,
      seatsNumber,
      trunkSize,
      transmission,
      wheelDrive,
      fuelType,
      tankVolumeInGal,
      distanceIncludedInMi,
      pricePerDay,
    } = carInfoFormParams;
    //Make sure that none of the fields are empty
    if (
      !name ||
      !description ||
      !vinNumber ||
      !licensePlate ||
      !state ||
      !brand ||
      !model ||
      !releaseYear ||
      !bodyType ||
      !color ||
      !doorsNumber ||
      !seatsNumber ||
      !trunkSize ||
      !transmission ||
      !wheelDrive ||
      !fuelType ||
      !tankVolumeInGal ||
      !distanceIncludedInMi ||
      !pricePerDay ||
      !fileURL
    )
      return;

    const attributes = [
      {
        trait_type: "VIN number",
        value: vinNumber,
      },
      {
        trait_type: "License plate",
        value: licensePlate,
      },
      {
        trait_type: "State",
        value: state,
      },
      {
        trait_type: "Brand",
        value: brand,
      },
      {
        trait_type: "Model",
        value: model,
      },
      {
        trait_type: "Release year",
        value: releaseYear,
      },
      {
        trait_type: "Body type",
        value: bodyType,
      },
      {
        trait_type: "Color",
        value: color,
      },
      {
        trait_type: "Doors number",
        value: doorsNumber,
      },
      {
        trait_type: "Seats number",
        value: seatsNumber,
      },
      {
        trait_type: "Trunk size",
        value: trunkSize,
      },
      {
        trait_type: "Transmission",
        value: transmission,
      },
      {
        trait_type: "Wheel drive",
        value: wheelDrive,
      },
      {
        trait_type: "Fuel type",
        value: fuelType,
      },
      {
        trait_type: "Tank volume(gal)",
        value: tankVolumeInGal,
      },
      {
        trait_type: "Distance included(mi)",
        value: distanceIncludedInMi,
      },
      {
        trait_type: "Price per Day (USD cents)",
        value: pricePerDay,
      },
    ];
    const nftJSON = {
      name,
      description,
      image: fileURL,
      attributes,
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
      listCarButtonRef.current.disabled = true;

      //Pull the deployed contract instance
      let contract = new ethers.Contract(
        RentCarJSON.address,
        RentCarJSON.abi,
        signer
      );

      var doubleNumber = Number(
        carInfoFormParams.pricePerDay.replace(/[^0-9.]+/g, "")
      );
      let pricePerDay = ((doubleNumber * 100) | 0).toString();
      //actually create the NFT
      let transaction = await contract.addCar(metadataURL, pricePerDay);
      await transaction.wait();

      alert("Successfully listed your car!");
      setMessage("");
      setCarInfoFormParams({
        name: "",
        description: "",
        vinNumber: "",
        licensePlate: "",
        state: "",
        brand: "",
        model: "",
        releaseYear: "",
        bodyType: "",
        color: "",
        doorsNumber: "",
        seatsNumber: "",
        trunkSize: "",
        transmission: "",
        wheelDrive: "",
        fuelType: "",
        tankVolumeInGal: "",
        distanceIncludedInMi: "",
        pricePerDay: "",
      });
      window.location.replace("/");
    } catch (e) {
      alert("Upload error" + e);
      listCarButtonRef.current.disabled = false;
    }
  };

  return (
    <div className="">
      <HostNavbar></HostNavbar>
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
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="vinNumber"
            >
              VIN number
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="vinNumber"
              type="text"
              placeholder="e.g. 4Y1SL65848Z411439"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  vinNumber: e.target.value,
                })
              }
              value={carInfoFormParams.vinNumber}
            ></input>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="licensePlate"
            >
              License plate
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="licensePlate"
              type="text"
              placeholder="e.g. ABC-12D"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  licensePlate: e.target.value,
                })
              }
              value={carInfoFormParams.licensePlate}
            ></input>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="state"
            >
              State
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="state"
              type="text"
              placeholder="e.g. New Jersey"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  state: e.target.value,
                })
              }
              value={carInfoFormParams.state}
            ></input>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="brand"
            >
              Car brand
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="brand"
              type="text"
              placeholder="e.g. Shelby"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  brand: e.target.value,
                })
              }
              value={carInfoFormParams.brand}
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
              id="model"
              type="text"
              placeholder="e.g. Mustang GT500"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  model: e.target.value,
                })
              }
              value={carInfoFormParams.model}
            ></input>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="releaseYear"
            >
              Release year
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="releaseYear"
              type="number"
              placeholder="e.g. 2023"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  releaseYear: e.target.value,
                })
              }
              value={carInfoFormParams.releaseYear}
            ></input>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="bodyType"
            >
              Body type
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="bodyType"
              type="text"
              placeholder="e.g. Sedan"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  bodyType: e.target.value,
                })
              }
              value={carInfoFormParams.bodyType}
            ></input>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="color"
            >
              Color
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="color"
              type="text"
              placeholder="e.g. Grey"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  color: e.target.value,
                })
              }
              value={carInfoFormParams.color}
            ></input>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="doorsNumber"
            >
              Number of doors
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="doorsNumber"
              type="text"
              placeholder="e.g. 2"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  doorsNumber: e.target.value,
                })
              }
              value={carInfoFormParams.doorsNumber}
            ></input>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="seatsNumber"
            >
              Number of seats
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="seatsNumber"
              type="text"
              placeholder="e.g. 5"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  seatsNumber: e.target.value,
                })
              }
              value={carInfoFormParams.seatsNumber}
            ></input>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="trunkSize"
            >
              Trunk size
            </label>
            <select
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="trunkSize"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  trunkSize: e.target.value,
                })
              }
              value={carInfoFormParams.trunkSize}
            >
              <option value="Small">Small</option>
              <option value="Medium">Medium</option>
              <option value="Large">Large</option>
            </select>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="transmission"
            >
              Transmission
            </label>
            <select
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="transmission"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  transmission: e.target.value,
                })
              }
              value={carInfoFormParams.transmission}
            >
              <option value="Manual">Manual</option>
              <option value="Automatic">Automatic</option>
            </select>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="wheelDrive"
            >
              Wheel drive
            </label>
            <select
              className="shadow border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="wheelDrive"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  wheelDrive: e.target.value,
                })
              }
              value={carInfoFormParams.wheelDrive}
            >
              <option value="Front">Front</option>
              <option value="Rear">Rear</option>
              <option value="4×4">4×4</option>
              <option value="All">All</option>
            </select>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="fuelType"
            >
              Fuel type
            </label>
            <select
              className="shadow border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="fuelType"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  fuelType: e.target.value,
                })
              }
              value={carInfoFormParams.fuelType}
            >
              <option value="Gasoline">Gasoline</option>
              <option value="Diesel">Diesel</option>
              <option value="Bio-diesel">Bio-diesel</option>
              <option value="Electro">Electro</option>
            </select>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="tankVolumeInGal"
            >
              Tank volume (gal)
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="tankVolumeInGal"
              type="text"
              placeholder="e.g. 16"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  tankVolumeInGal: e.target.value,
                })
              }
              value={carInfoFormParams.tankVolumeInGal}
            ></input>
          </div>
          <div className="mb-4">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="distanceIncludedInMi"
            >
              Distance included (mi)
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              id="distanceIncludedInMi"
              type="text"
              placeholder="e.g. 200"
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  distanceIncludedInMi: e.target.value,
                })
              }
              value={carInfoFormParams.distanceIncludedInMi}
            ></input>
          </div>
          <div className="mb-6">
            <label
              className="block text-purple-500 text-sm font-bold mb-2"
              htmlFor="pricePerDay"
            >
              Price per day (in USD)
            </label>
            <input
              className="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
              type="number"
              placeholder="e.g. 100"
              step="1"
              value={carInfoFormParams.pricePerDay}
              onChange={(e) =>
                setCarInfoFormParams({
                  ...carInfoFormParams,
                  pricePerDay: e.target.value,
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
            ref={listCarButtonRef}
            onClick={listCar}
            className="font-bold mt-10 w-full bg-purple-500 disabled:bg-gray-500 text-white rounded p-2 shadow-lg"
          >
            List car
          </button>
        </form>
      </div>
    </div>
  );
}
