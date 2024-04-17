import { useEffect, useState } from "react";
import { ethers } from "ethers";
import PropertyTokenABI from "../contracts/PropertyTokenABI.json";

export default function PropertyDetails({ propertyAddress }) {
  const [provider, setProvider] = useState(null);
  const [propertyName, setPropertyName] = useState("");
  const [propertySymbol, setPropertySymbol] = useState("");
  const [propertyOwner, setPropertyOwner] = useState("");

  useEffect(() => {
    async function initialize() {
      try {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        setProvider(provider);

        const propertyContract = new ethers.Contract(
          propertyAddress,
          PropertyTokenABI,
          provider,
        );
        const name = await propertyContract.name();
        const symbol = await propertyContract.symbol();
        const owner = await propertyContract.getOwner();

        setPropertyName(name);
        setPropertySymbol(symbol);
        setPropertyOwner(owner);
      } catch (error) {
        console.error("Error connecting to provider:", error);
      }
    }

    initialize();
  }, [propertyAddress]);

  return (
    <div>
      <h1>Property Details</h1>
      <p>Name: {propertyName}</p>
      <p>Symbol: {propertySymbol}</p>
      <p>Owner: {propertyOwner}</p>
    </div>
  );
}

export async function getServerSideProps(context) {
  const { propertyAddress } = context.query;
  return {
    props: { propertyAddress },
  };
}
