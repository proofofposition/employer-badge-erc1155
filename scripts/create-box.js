// scripts/create-box.js
const { ethers, upgrades } = require("hardhat");

async function main() {
    console.log("Starting...");
    const PoppEmployerBadge = await ethers.getContractFactory("PoppEmployerBadge");
    const poppEmployerBadge = await upgrades.deployProxy(PoppEmployerBadge);
    console.log("Deploying PoppEmployerBadge...");
    await poppEmployerBadge.deployed();
    console.log("PoppEmployerBadge deployed to:", poppEmployerBadge.address);
}

main();
