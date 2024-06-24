//// SPDX-License-Identifier: MIT
//pragma solidity ^0.8.9;
//
//import "../RentalityGateway.sol";
//import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
//import "../proxy/IRentalityUpdatable.sol";
//
///// @title Rentality Admin Gateway Interface
///// @dev Interface for the RentalityAdminGateway contract,
///// providing administrative functionalities for the Rentality platform.
//abstract contract IRentalityContractFabric {
//    uint private contractsCounter;
//    uint private maxSize;
//    mapping(address => bool) private isRentality;
//    RentalityContract private addresses;
//
//    modifier requireAllowance () {
//        require(addresses.userService.isAdmin(msg.sender), "Only admin");
//
//        _;
//    }
//    function deploy(bytes memory bytecode) requireAllowance() public returns (address) {
//        require(contractsCounter != maxSize, "Already deployed");
//        address newContract;
//
//        assembly {
//            newContract := create(msg.value, bytecode, add(bytecode, mload(bytecode)))
//        }
//        require(newContract != address(0), "Fail to deploy");
//        contractsCounter += 1;
//        return _saveToFactory(newContract, address(0));
//    }
//
//    function deployAndRemove(bytes memory bytecode, address prevContract) requireAllowance() public returns (address) {
//        require(isRentality[prevContract], 'Is not Rentality.');
//
//        address newContract;
//        assembly {
//            newContract :=  create(msg.value, bytecode, add(bytecode, mload(bytecode)))
//        }
//        require(newContract != address(0), "Fail to deploy");
//        return _saveToFactory(newContract, prevContract);
//    }
//
//
//    function _saveToFactory(address newContract, address old) internal returns (address) {
//        _substitute(old, newContract);
//        isRentality[newContract] = true;
//        update();
//        return newContract;
//    }
//
//    function _deploy(bytes memory bytecode) internal returns (address) {
//        address newContract;
//        assembly {
//            newContract := create(0, bytecode, add(bytecode, mload(bytecode)))
//        }
//        require(newContract != address(0), "Fail to deploy");
//        addresses = IRentalityFactoryChild(newContract).updateRentalityContracts(addresses);
//        return newContract;
//    }
//
//    function deployProxyContract(bytes memory bytecode, bytes calldata init) requireAllowance public returns (address) {
//        require(contractsCounter != maxSize, "Already deployed");
//        address newContract = _deploy(bytecode);
//        IRentalityUpdatable proxyContract = IRentalityUpdatable(address(new ERC1967Proxy(newContract, init)));
//        addresses = proxyContract.updateRentalityContractsWithThis(addresses);
//        contractsCounter += 1;
//        return _saveToFactory(newContract, addresses(0));
//    }
//
//    function updateProxy(address target, bytes memory bytecode, bytes calldata init) requireAllowance() public {
//        require(isRentality[target], "It's not rentality contract");
//        address newContract = _deploy(bytecode);
//        if (init.length != 0) {
//            IRentalityUpdatable(target).upgradeToAndCall(newContract, init);
//        }
//        else {
//            IRentalityUpdatable(target).upgradeTo(newContract);
//        }
//    }
//
//    function _substitute(address target, address newAddress) internal {
//        address s;
//        for (uint i = 0; i <= contractsCounter; i++) {
//            assembly {
//                s := sload(add(addresses.slot, i))
//                if eq(s, from) {
//                    sstore(add(addresses.slot, i), to)
//                    return (0, 0)
//                }
//            }
//        }
//    }
//
//
//    function update() public {
//        for (uint i = 0; i < contractsCounter; i++) {
//            address target;
//            assembly {
//                target := sload(add(addresses.slot, i))
//            }
//            IRentalityFactoryChild(target).updateRentalityContracts(addresses);
//        }
//
//    }
//
//    function getContracts() public view returns (RentalityContract memory) {
//        return addresses;
//    }
//}