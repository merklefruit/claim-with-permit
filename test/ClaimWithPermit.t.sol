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

    function test_SuccessfullyClaimWithPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({spender: claimer, rewardId: 1, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(verifierPrivateKey, digest);

        vm.prank(claimer);
        claimWithPermit.claim(permit.rewardId, permit.deadline, v, r, s);

        assertEq(claimWithPermit.balanceOf(claimer), 1);
        assertEq(claimWithPermit.verifierNonce(), 1);
    }

    function testRevert_ExpiredPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({spender: claimer, rewardId: 1, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(verifierPrivateKey, digest);

        vm.prank(claimer);
        vm.warp(1 days + 1 seconds); // fast forward one second past the deadline
        vm.expectRevert(ClaimWithPermit.PermitDeadlineExpired.selector);
        claimWithPermit.claim(permit.rewardId, permit.deadline, v, r, s);
    }

    function testRevert_InvalidSignature() public {
        SigUtils.Permit memory permit = SigUtils.Permit({spender: claimer, rewardId: 1, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        // sign the permit with the claimer's private key instead of the verifier's
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(claimerPrivateKey, digest);

        vm.prank(claimer);
        vm.expectRevert(ClaimWithPermit.InvalidSignature.selector);
        claimWithPermit.claim(permit.rewardId, permit.deadline, v, r, s);
    }

    function testRevert_InvalidNonce() public {
        // use a nonce of 1 instead of 0
        SigUtils.Permit memory permit = SigUtils.Permit({spender: claimer, rewardId: 1, nonce: 1, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(verifierPrivateKey, digest);

        vm.prank(claimer);
        vm.expectRevert(ClaimWithPermit.InvalidSignature.selector);
        claimWithPermit.claim(permit.rewardId, permit.deadline, v, r, s);
    }

    function testRevert_SignatureReplay() public {
        SigUtils.Permit memory permit = SigUtils.Permit({spender: claimer, rewardId: 1, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(verifierPrivateKey, digest);

        vm.prank(claimer);
        claimWithPermit.claim(permit.rewardId, permit.deadline, v, r, s);

        // try to claim a second time with the same signed message
        vm.expectRevert(ClaimWithPermit.InvalidSignature.selector);
        claimWithPermit.claim(permit.rewardId, permit.deadline, v, r, s);
    }

    function testRevert_signatureSniff() public {
        SigUtils.Permit memory permit = SigUtils.Permit({spender: claimer, rewardId: 1, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(verifierPrivateKey, digest);

        // try to claim with a signature that was signed by the verifier but for a different spender
        address sniffer = vm.addr(uint256(keccak256("sniffer")));
    
        vm.prank(sniffer);
        vm.expectRevert(ClaimWithPermit.InvalidSignature.selector);
        claimWithPermit.claim(permit.rewardId, permit.deadline, v, r, s);
    }
}
