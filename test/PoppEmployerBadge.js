//
// this script executes when you run 'yarn test'
//
// you can also test remote submissions like:
// CONTRACT_ADDRESS=0x43Ab1FCd430C1f20270C2470f857f7a006117bbb yarn test --network rinkeby
//
// you can even run mint commands if the tests pass like:
// yarn test && echo "PASSED" || echo "FAILED"
//
const {expect} = require("chai");

describe("🚩 Full Popp Employer Verification Flow", function () {
    this.timeout(120000);

    let myContract;
    // eslint-disable-next-line no-unused-vars
    let owner;
    let alice;
    let connie;
    let bob;
    let tokenId;

    // console.log("hre:",Object.keys(hre)) // <-- you can access the hardhat runtime env here

    describe("Popp Verification", function () {
        // `beforeEach` will run before each test, re-deploying the contract every
        // time. It receives a callback, which can be async.
        beforeEach(async function () {
            // deploy contract
            const PoppEmployerBadge = await ethers.getContractFactory("PoppEmployerBadge");
            myContract = await PoppEmployerBadge.deploy();

            [owner, alice, bob, connie] = await ethers.getSigners();
            const balance0ETH = await ethers.provider.getBalance(myContract.address);
            console.log("\t", " ⚖️ Starting Contract ETH balance: ", balance0ETH.toString());

            // mint employer verification
            let mintResult = await myContract
                .connect(owner)
                .mintNewBadge(alice.address, "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr");

            // check transaction was successful
            let txResult = await mintResult.wait(1);
            tokenId = txResult.events[0].args.tokenId.toString();

            expect(txResult.status).to.equal(1);

            let balance = await myContract.balanceOf(alice.address);
            expect(balance.toBigInt()).to.be.equal(1);

            // check token uri
            let uri = await myContract.tokenURI(tokenId);
            expect(uri).to.be.equal("QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr");
        });

        describe("mintNewBadge()", function () {
            it("Should be able to mint an employer verification token and add wallet", async function () {
                // add a new wallet
                let mintResult = await myContract
                    .connect(alice)
                    .addToTeam(connie.address, tokenId);
                // check uri is the same for the new wallet token
                let txResult = await mintResult.wait(1);
                let newTokenId = txResult.events[0].args.tokenId.toString();
                let uri = await myContract.tokenURI(newTokenId);
                expect(uri).to.be.equal("QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr");
                console.log(tokenId);

            });

            it("Should fail if non-owner wallet tries to mint a new token", async function () {
                await expect(myContract
                    .connect(alice)
                    .mintNewBadge(alice.address, "QmfVMAmNM1kDEBYrC2TPzQDoCRFH6F5tE1e9Mr4FkkR5Xr")).to.be.revertedWith("Ownable: caller is not the owner");
            });

            it("Should fail if non-owner wallet tries to add a new wallet", async function () {
                await expect(myContract
                    .connect(bob)
                    .addToTeam(bob.address, tokenId)).to.be.revertedWith("Only the owner can do this");
            });

            it("Should be able to burn token (admin only)", async function () {
                await myContract
                    .connect(owner)
                    .burn(tokenId)

                let balance = await myContract.balanceOf(alice.address);
                expect(balance.toBigInt()).to.be.equal(0);
            });
        });
    });
});
