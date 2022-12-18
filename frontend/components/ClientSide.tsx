import dynamic from "next/dynamic";
import React from "react";

const ClientSide = (props: any) => (
  <React.Fragment>{props.children}</React.Fragment>
);

export default dynamic(() => Promise.resolve(ClientSide), {
  ssr: false,
});
