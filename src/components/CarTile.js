import { Link } from "react-router-dom";

export default function CarTile({ carInfo }) {
  const carInfoPath = {
    pathname: "/carInfo/" + carInfo.tokenId,
  };
  return (
    <Link to={carInfoPath}>
      <div className="border-2 ml-12 mt-5 mb-12 flex flex-col items-center rounded-lg w-48 md:w-72 shadow-2xl">
        <img
          src={carInfo.image}
          alt=""
          className="w-72 h-80 rounded-lg object-cover"
        />
        <div className="text-white w-full p-2 bg-gradient-to-t from-[#454545] to-transparent rounded-lg pt-5 -mt-20">
          <strong className="text-xl">{carInfo.name}</strong>
          <p className="display-inline">
            <strong className="text-l">{carInfo.model}</strong>
          </p>
          <p className="display-inline">{carInfo.description}</p>
        </div>
      </div>
    </Link>
  );
}
