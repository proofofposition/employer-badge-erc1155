const { ethers, upgrades } = require("hardhat");

async function main() {
    const PoppEmployerBadge = await ethers.getContractFactory("PoppEmployerBadge");
    const poppEmployerBadge = await upgrades.upgradeProxy(BOX_ADDRESS, PoppEmployerBadge);
    console.log("PoppEmployerBadge upgraded");
}

main();