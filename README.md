# Claim with Permit • Digital signature scheme for allow-listed token claims

Working proof of concept for a digital signature scheme that allows a user to only claim a token with a signed permission. The permit is a message signed by a verifier (a trusted party) that allows the claim to be executed by the user. The claim is only valid if the permit is valid.

## Contributing

You will need a copy of [Foundry](https://github.com/foundry-rs/foundry) installed before proceeding. See the [installation guide](https://github.com/foundry-rs/foundry#installation) for details.

### Setup

```sh
git clone https://github.com/nicolas-racchi/claim-with-permit.git
cd claim-with-permit
forge install
```

### Run Tests

```sh
forge test
```

### Update Gas Snapshots

```sh
forge snapshot
```

### Credits

- This repo was bootstrapped with the [Foundry template](https://github.com/transmissions11/foundry-template) by [t11s](https://github.com/transmissions11).
