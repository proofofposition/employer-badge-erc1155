const { ethers, upgrades } = require("hardhat");
const UPGRADEABLE_CONTRACT_ADDRESS = "0xb7D2887361C90DDf1f1B4630D222C1C9E477ed3d";
// sepolia 0x68cd710FeF09705d761D8E2a7b640978a25313d4
async function main() {
    console.log("Starting...");
    const PoppEmployerBadge = await ethers.getContractFactory("PoppEmployerBadge");
    console.log("Deploying PoppEmployerBadge...");
    const poppEmployerBadge = await upgrades.upgradeProxy(UPGRADEABLE_CONTRACT_ADDRESS, PoppEmployerBadge);
    console.log("PoppEmployerBadge upgraded at :", UPGRADEABLE_CONTRACT_ADDRESS);
}

main();