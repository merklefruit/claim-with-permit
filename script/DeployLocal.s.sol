// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Script.sol";

import {ClaimWithPermit} from "src/ClaimWithPermit.sol";

import {SigUtils} from "test/utils/SigUtils.sol";

contract DeployLocal is Script {
    function run() public {
        address verifier = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // anvil default 0

        vm.startBroadcast(verifier);

        ClaimWithPermit claimWithPermit = new ClaimWithPermit("Test", "TEST", verifier);

        SigUtils sigUtils = new SigUtils(claimWithPermit.DOMAIN_SEPARATOR(), claimWithPermit.PERMIT_TYPEHASH());

        vm.stopBroadcast();
    }
}
