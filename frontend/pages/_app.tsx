import "../styles/globals.css";

import { configureChains, createClient, WagmiConfig } from "wagmi";
import { foundry } from "wagmi/chains";
import { InjectedConnector } from "wagmi/connectors/injected";
import { jsonRpcProvider } from "wagmi/providers/jsonRpc";

import type { AppProps } from "next/app";

const { provider, chains } = configureChains(
  [foundry],
  [jsonRpcProvider({ rpc: () => ({ http: "http://127.0.0.1:8545" }) })]
);

const client = createClient({
  autoConnect: true,
  connectors: [new InjectedConnector({ chains })],
  provider,
});

export default function App({ Component, pageProps }: AppProps) {
  return (
    <WagmiConfig client={client}>
      <Component {...pageProps} />
    </WagmiConfig>
  );
}
