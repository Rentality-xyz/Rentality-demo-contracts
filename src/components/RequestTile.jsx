import React, { useRef } from "react";

export default function RequestTile({ requestInfo, onApprove, onReject }) {
  const approveButtonRef = useRef();
  const rejectButtonRef = useRef();

  const formatAddress = (address) => {
    if (address == null || address.length < 10) return address;
    return address.substr(0, 5) + ".." + address.substr(address.length - 5);
  };

  const handleApproveClick = async () => {
    approveButtonRef.current.disabled = true;
    rejectButtonRef.current.disabled = true;
    await onApprove(requestInfo);
    approveButtonRef.current.disabled = false;
    rejectButtonRef.current.disabled = false;
  };

  const handleRejectClick = async () => {
    approveButtonRef.current.disabled = true;
    rejectButtonRef.current.disabled = true;
    await onReject(requestInfo);
    approveButtonRef.current.disabled = false;
    rejectButtonRef.current.disabled = false;
  };

  return (
    <div className="border-2 flex flex-col items-center rounded-md w-full shadow-2xl">
      <div className="flex flex-row items-center mt-2 mx-4 w-full">
        <img
          src={requestInfo.image}
          alt=""
          className="ml-4 w w-16 h-16 rounded-sm object-cover"
        />
        <div className="text-white w-full">
          <strong className="text-1">{requestInfo.name}</strong>
          <p className="display-inline">
            <strong className="text-sm">
              from {formatAddress(requestInfo.renter)}
            </strong>
            <strong className="text-sm"> for {requestInfo.daysForRent} day(s)</strong>
          </p>
          <p className="display-inline"></p>
          <p className="display-inline">
            <strong className="text-2">for ${requestInfo.totalPrice}</strong>
          </p>
        </div>
      </div>
      <div className="flex flex-row items-center mt-2 mb-2">
        <button
          ref={approveButtonRef}
          className="approveButton bg-blue-500 hover:bg-blue-700 disabled:bg-gray-500 text-white font-bold mx-5 py-2 px-4 rounded text-sm"
          onClick={handleApproveClick}
        >
          Approve
        </button>
        <button
          ref={rejectButtonRef}
          className="rejectButton bg-red-500 hover:bg-red-700 disabled:bg-gray-500 text-white font-bold mx-5 py-2 px-4 rounded text-sm"
          onClick={handleRejectClick}
        >
          Reject
        </button>
      </div>
    </div>
  );
}
