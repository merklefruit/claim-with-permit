// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";

contract ClaimWithPermit is ERC721 {
    error PermitDeadlineExpired();
    error InvalidSignature();
    error AlreadyClaimed();

    event Claim(address indexed user, uint256 indexed tokenId, uint256 rewardId);

    // address of our backend server that will sign the message to authorize the mint
    address public verifier;

    // keccak of the Permit struct used to build the eip712 signature
    bytes32 public immutable PERMIT_TYPEHASH;

    // keccak of the EIP712Domain struct for this contract
    bytes32 public immutable DOMAIN_SEPARATOR;

    // nonce used to prevent signature replay attacks
    uint256 public verifierNonce;

    uint256 public tokenId;
    mapping(address => bool) public hasClaimed;

    constructor(string memory _name, string memory _symbol, address _verifier) ERC721(_name, _symbol) {
        PERMIT_TYPEHASH = keccak256("Permit(address spender,uint256 rewardId,uint256 nonce,uint256 deadline)");
        DOMAIN_SEPARATOR = computeDomainSeparator();
        verifier = _verifier;
    }

    // execute the mint with permit by verifying the off-chain verifier signature
    function claim(uint256 rewardId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual {
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        if (deadline <= block.timestamp) revert PermitDeadlineExpired();

        // Unchecked because the only math done is incrementing
        // the verifier's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR,
                        // Permit: { spender, rewardId, nonce, deadline }
                        keccak256(abi.encode(PERMIT_TYPEHASH, msg.sender, rewardId, verifierNonce++, deadline))
                    )
                ),
                v,
                r,
                s
            );

            if (recoveredAddress == address(0) || recoveredAddress != verifier) revert InvalidSignature();
        }

        mintReward(msg.sender, rewardId);
    }

    function mintReward(address recipient, uint256 rewardId) internal {
        _safeMint(recipient, ++tokenId);
        emit Claim(recipient, tokenId, rewardId);
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked("https://example.com/token/", _tokenId));
    }
}
