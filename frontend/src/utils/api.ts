// api.js
import { ethers } from "ethers";
import PropertyManagerABI from "./contracts/PropertyManagerABI.json"; // removed from the  repo since its sensitive
import PropertyTokenABI from "./contracts/PropertyTokenABI.json";

class API {
  constructor() {
    this.provider = null;
    this.propertyManager = null;
  }

  async initialize() {
    try {
      this.provider = new ethers.providers.Web3Provider(window.ethereum);
      this.propertyManager = new ethers.Contract(
        "YOUR_PROPERTY_MANAGER_CONTRACT_ADDRESS",
        PropertyManagerABI,
        this.provider,
      );
    } catch (error) {
      console.error("Error initializing API:", error);
    }
  }

  async fetchUserProperties(userAddress) {
    try {
      const propertyCount = await this.propertyManager.propertyCount();
      const userProperties = [];

      for (let i = 1; i <= propertyCount; i++) {
        const property = await this.propertyManager.properties(i);
        const propertyContract = new ethers.Contract(
          property,
          PropertyTokenABI,
          this.provider,
        );
        const owner = await propertyContract.getOwner();

        if (owner === userAddress) {
          userProperties.push(property);
        }
      }

      return userProperties;
    } catch (error) {
      console.error("Error fetching user properties:", error);
      return [];
    }
  }

  async fetchPropertyDetails(propertyAddress) {
    try {
      const propertyContract = new ethers.Contract(
        propertyAddress,
        PropertyTokenABI,
        this.provider,
      );
      const name = await propertyContract.name();
      const symbol = await propertyContract.symbol();
      const owner = await propertyContract.getOwner();

      return { name, symbol, owner };
    } catch (error) {
      console.error("Error fetching property details:", error);
      return null;
    }
  }
}

export default new API();
