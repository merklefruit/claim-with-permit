import { ethers } from "ethers";
import { keccak256 } from "ethers/lib/utils.js";
import Head from "next/head";
import { useState } from "react";
import {
    useAccount, useConnect, useContractWrite, useDisconnect, useNetwork, usePrepareContractWrite,
    useSwitchNetwork, useWaitForTransaction
} from "wagmi";
import { InjectedConnector } from "wagmi/connectors/injected";

import { Inter } from "@next/font/google";

import ClaimWithPermit from "../abi/ClaimWithPermit.json";
import SigUtils from "../abi/SigUtils.json";
import ClientSide from "../components/ClientSide";

const inter = Inter({ subsets: ["latin"] });

// @dev this is the default private key for Hardhat and Foundry toolkit, safe to be publicly shared
const verifierPrivateKey =
  "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

const claimWithPermitAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const sigUtilsAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

export default function Home() {
  const { chain } = useNetwork();
  const { address, isConnected } = useAccount();
  const { chains, switchNetwork } = useSwitchNetwork();
  const { connect } = useConnect({ connector: new InjectedConnector() });
  const { disconnect } = useDisconnect();

  const [signature, setSignature] = useState<any>();

  const { config } = usePrepareContractWrite({
    address: claimWithPermitAddress,
    abi: ClaimWithPermit.abi,
    functionName: "claim",
    args: [1, 1e10, signature?.v, signature?.r, signature?.s],
    enabled: !!signature,
  });

  const { data: writeData, write } = useContractWrite(config);
  const { isLoading, isSuccess } = useWaitForTransaction({
    hash: writeData?.hash,
  });

  // NOTE: in a production dapp, this should run in a server, not in the browser
  // @dev uses the verifier's private key to create a signature for the claim
  const createClaimSignature = async (recipient: string) => {
    const verifier = new ethers.Wallet(
      verifierPrivateKey,
      new ethers.providers.JsonRpcProvider("http://localhost:8545")
    );
    const sigUtils = new ethers.Contract(
      sigUtilsAddress,
      SigUtils.abi,
      verifier
    );

    try {
      const domainSeparator = await sigUtils.DOMAIN_SEPARATOR();
      console.log("domainSeparator: ", domainSeparator);

      const digest = await sigUtils.getTypedDataHash([recipient, 1, 0, 1e13]);

      console.log("digest: ", digest);

      const signature = await verifier.signMessage(digest);

      console.log("signature: ", signature);

      return signature;
    } catch (err) {
      console.error(err);
      return null;
    }
  };

  // @dev uses the connected wallet to execute the claim transaction
  const executeClaim = async () => {
    // simulate off-chain message signing on the server
    const signature = await createClaimSignature(address as string);
    if (signature) write?.();

    console.log(writeData);
  };

  return (
    <>
      <Head>
        <title>Claim with permit</title>
        <meta name="description" content="Generated by create next app" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className={inter.className.concat(" px-4 container mx-auto")}>
        <div className="mt-16">
          <h1 className="text-center text-3xl">Claim with Permit</h1>

          <ClientSide>
            <div className="mt-8 flex max-w-md gap-3 mx-auto">
              <div className="mx-auto w-full flex flex-col gap-8">
                <h2 className="text-xl">Step 1:</h2>

                <button
                  type="button"
                  onClick={() => (isConnected ? disconnect() : connect())}
                  className="w-full inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  {isConnected ? "Disconnect wallet" : "Connect wallet"}
                </button>

                {isConnected && (
                  <div className="text-center">
                    <p className="text-sm">Connected with address:</p>
                    <p className="text-sm">{address}</p>
                    <p className="text-sm">Connected to {chain?.name}</p>
                  </div>
                )}

                <h2 className="text-xl">Step 2:</h2>

                <div className="flex flex-col gap-2 w-full">
                  <button
                    type="button"
                    onClick={() => switchNetwork?.(chains[0]?.id)}
                    className="mt-4 w-full inline-flex justify-center py-2 px-4 border border-transparent shadow-sm 
                    text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none 
                    focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    {chain?.id !== 31337 ? (
                      <p>
                        Switch to {chains[0]?.name} network ({chains[0]?.id})
                      </p>
                    ) : (
                      <p>On Foundry network!</p>
                    )}
                  </button>
                </div>

                <h2 className="text-xl">Step 3:</h2>

                <button
                  type="button"
                  onClick={executeClaim}
                  className="mt-4 w-full inline-flex justify-center py-2 px-4 border border-transparent shadow-sm 
                  text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none 
                  focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                >
                  Claim!
                </button>
              </div>
            </div>
          </ClientSide>
        </div>
      </main>
    </>
  );
}
