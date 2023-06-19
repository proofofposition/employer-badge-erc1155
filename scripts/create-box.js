// scripts/create-box.js
const { ethers, upgrades } = require("hardhat");

async function main() {
    const PoppEmployerBadge = await ethers.getContractFactory("PoppEmployerBadge");
    const poppEmployerBadge = await upgrades.deployProxy(PoppEmployerBadge, [42]);
    await poppEmployerBadge.deployed();
    console.log("PoppEmployerBadge deployed to:", poppEmployerBadge.address);
}

main();
