import { useEffect, useState } from "react";
import { ethers } from "ethers";
import PropertyManagerABI from "../contracts/PropertyManagerABI.json";
import PropertyTokenABI from "../contracts/PropertyTokenABI.json";

export default function UserProperties() {
  const [provider, setProvider] = useState(null);
  const [userAddress, setUserAddress] = useState("");
  const [properties, setProperties] = useState([]);

  useEffect(() => {
    async function initialize() {
      try {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        setProvider(provider);

        const accounts = await provider.listAccounts();
        setUserAddress(accounts[0]);
      } catch (error) {
        console.error("Error connecting to provider:", error);
      }
    }

    initialize();
  }, []);

  async function fetchProperties() {
    try {
      const propertyManagerAddress = "YOUR_PROPERTY_MANAGER_CONTRACT_ADDRESS";
      const propertyManager = new ethers.Contract(
        propertyManagerAddress,
        PropertyManagerABI,
        provider,
      );

      const propertyCount = await propertyManager.propertyCount();
      const userProperties = [];

      for (let i = 1; i <= propertyCount; i++) {
        const property = await propertyManager.properties(i);
        const propertyContract = new ethers.Contract(
          property,
          PropertyTokenABI,
          provider,
        );
        const owner = await propertyContract.getOwner();

        if (owner === userAddress) {
          userProperties.push(property);
        }
      }

      setProperties(userProperties);
    } catch (error) {
      console.error("Error fetching properties:", error);
    }
  }

  return (
    <div>
      <h1>Your Properties</h1>
      <button onClick={fetchProperties}>Fetch Properties</button>
      <ul>
        {properties.map((property, index) => (
          <li key={index}>{property}</li>
        ))}
      </ul>
    </div>
  );
}
