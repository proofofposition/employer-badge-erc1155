const { ethers, upgrades } = require("hardhat");
// sepolia
 const UPGRADEABLE_CONTRACT_ADDRESS = "0x1D831564d1c3FF8337530AE54C9D6B3f37ED5A5a";
// base goerli
//const UPGRADEABLE_CONTRACT_ADDRESS = "0x57172fC26F83BD18850B5657f62d2fa09Cd1C4dD";
async function main() {
    console.log("Starting...");
    const PoppEmployerBadge = await ethers.getContractFactory("PoppEmployerBadge");
    console.log("Deploying PoppEmployerBadge...");
    const poppEmployerBadge = await upgrades.upgradeProxy(UPGRADEABLE_CONTRACT_ADDRESS, PoppEmployerBadge);
    console.log("PoppEmployerBadge upgraded at :", UPGRADEABLE_CONTRACT_ADDRESS);
}

main();