const { ethers, upgrades } = require("hardhat");
// polygon
// const UPGRADEABLE_CONTRACT_ADDRESS = "0x5ac201677356b7862B88126cDcB3921FEfDcde82";
// sepolia
 const UPGRADEABLE_CONTRACT_ADDRESS = "0x0FC0fd31C2465367047127a87Fda2a565EC0AcA5";
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