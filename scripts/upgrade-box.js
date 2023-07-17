const { ethers, upgrades } = require("hardhat");
const UPGRADEABLE_CONTRACT_ADDRESS = "0xbA48b6AC88761d8B153E50Ca882FB4Ae798f57df";
// sepolia 0x71763e216f4C68e8865F8dd1f060E2f1C5fb14c3
async function main() {
    console.log("Starting...");
    const PoppEmployerBadge = await ethers.getContractFactory("PoppEmployerBadge");
    console.log("Deploying PoppEmployerBadge...");
    const poppEmployerBadge = await upgrades.upgradeProxy(UPGRADEABLE_CONTRACT_ADDRESS, PoppEmployerBadge);
    console.log("PoppEmployerBadge upgraded at :", UPGRADEABLE_CONTRACT_ADDRESS);
}

main();