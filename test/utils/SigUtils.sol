// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract SigUtils {
    bytes32 internal DOMAIN_SEPARATOR;
    bytes32 internal PERMIT_TYPEHASH;

    constructor(bytes32 _DOMAIN_SEPARATOR, bytes32 _PERMIT_TYPEHASH) {
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
        PERMIT_TYPEHASH = _PERMIT_TYPEHASH;
    }

    struct Permit {
        address spender;
        uint256 rewardId;
        uint256 nonce;
        uint256 deadline;
    }

    // computes the hash of a permit
    function getStructHash(Permit memory _permit) internal view returns (bytes32) {
        return
            keccak256(abi.encode(PERMIT_TYPEHASH, _permit.spender, _permit.rewardId, _permit.nonce, _permit.deadline));
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(Permit memory _permit) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getStructHash(_permit)));
    }
}
