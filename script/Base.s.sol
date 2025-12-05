// SPDX-License-Identifier: MIT License
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";

contract BaseScript is Script {
    address internal deployer;
    bytes32 internal salt;

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }

    function setUp() public virtual {
        // Try PRIVATE_KEY first (for testnet/mainnet), fall back to PRIVATE_KEY_ANVIL (for local)
        bytes32 privateKey;
        try vm.envBytes32("PRIVATE_KEY") returns (bytes32 pk) {
            privateKey = pk;
        } catch {
            privateKey = vm.envBytes32("PRIVATE_KEY_ANVIL");
        }
        deployer = vm.rememberKey(uint256(privateKey));
        
        // SALT is optional
        try vm.envBytes32("SALT") returns (bytes32 s) {
            salt = s;
        } catch {
            salt = bytes32(0);
        }
    }
}
