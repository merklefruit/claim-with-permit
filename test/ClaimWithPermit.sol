// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "forge-std/Test.sol";

import {ClaimWithPermit} from "src/ClaimWithPermit.sol";

import {SigUtils} from "./utils/SigUtils.sol";

contract ERC20Test is Test {
    ClaimWithPermit internal claimWithPermit;
    SigUtils internal sigUtils;

    uint256 internal verifierPrivateKey;
    uint256 internal claimerPrivateKey;

    address internal verifier;
    address internal claimer;

    function setUp() public {
        verifierPrivateKey = uint256(keccak256("verifier"));
        claimerPrivateKey = uint256(keccak256("claimer"));

        verifier = vm.addr(verifierPrivateKey);
        claimer = vm.addr(claimerPrivateKey);

        claimWithPermit = new ClaimWithPermit("Test", "TEST", verifier);
        sigUtils = new SigUtils(claimWithPermit.DOMAIN_SEPARATOR(), claimWithPermit.PERMIT_TYPEHASH());
    }

    function testClaimWithPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({spender: claimer, rewardId: 1, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(verifierPrivateKey, digest);

        vm.prank(claimer);
        claimWithPermit.claim(permit.rewardId, permit.deadline, v, r, s);

        assertEq(claimWithPermit.balanceOf(claimer), 1);
        assertEq(claimWithPermit.verifierNonce(), 1);
    }
}
