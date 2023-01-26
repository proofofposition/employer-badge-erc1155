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
                .mintNewBadge(alice.address);

            let batch = await myContract.balanceOfBatch([alice.address], [1])
            expect(batch.toString()).to.equal('1');
            // check transaction was successful
            let txResult = await mintResult.wait(1);
            tokenId = txResult.events[0].args.id.toString();

            expect(txResult.status).to.equal(1);

            let balance = await myContract.balanceOf(alice.address, tokenId);
            expect(balance.toBigInt()).to.be.equal(1);

            // check token uri
            let uri = await myContract.uri(tokenId);
            expect(uri).to.be.equal("https://ipfs.io/ipfs/QmZ2tGMUt8AndeghM5CL3pfZqcWaEos8YdqjxyRVtk4XGF?filename={id}.json");

            await expect(
                myContract
                    .connect(bob)
                    .mintNewBadge(bob.address)
            ).to.be.revertedWith("Ownable: caller is not the owner");

            // test non-transferable
            await expect(
                myContract.safeTransferFrom(owner.address, alice.address, 1, 1, "0x")
            ).to.be.revertedWith("Employer badges are non-transferable");
        });

        describe("addToTeam()", function () {
            it("Owner should add a wallet to a pre-existing team", async function () {
                // add to team
                await myContract
                    .addToTeam(connie.address, 1);

                expect(await myContract.employerIdFromWallet(connie.address)).to.equal(
                    1
                );
            });

            it("Should fail non-owner to add to team", async function () {
                // add a new wallet
                await expect(
                    myContract
                        .connect(bob)
                        .addToTeam(connie.address, 1)
                ).to.be.revertedWith("Ownable: caller is not the owner");
            });
        });

        describe("addToMyTeam()", function () {
            it("Should be able to add a wallet to my team", async function () {
                // add a new wallet
                let mintResult = await myContract
                    .connect(alice)
                    .addToMyTeam(connie.address);
                // check uri is the same for the new wallet token
                let txResult = await mintResult.wait(1);
                let _tokenId = txResult.events[0].args.id.toString();
                expect(_tokenId).to.be.equal("1");

                await expect(
                    myContract
                        .connect(alice)
                        .addToMyTeam(connie.address)
                ).to.be.revertedWith("Wallet already apart of a team");
            });

            it("Should fail if user tries to add to a non-existent team", async function () {
                // add a new wallet
                await expect(
                    myContract
                        .connect(bob)
                        .addToMyTeam(connie.address)
                ).to.be.revertedWith("You need to register your employer");
            });

            it("Should be able to remove from team (admin)", async function () {
                await myContract
                    .connect(owner)
                    .removeFromTeam(alice.address, tokenId)

                let balance = await myContract.balanceOf(alice.address, tokenId);
                expect(balance.toBigInt()).to.be.equal(0);
            });

            it("Should be able to remove from team (team member)", async function () {
                await myContract
                    .connect(alice)
                    .removeFromMyTeam(alice.address)

                let balance = await myContract.balanceOf(alice.address, tokenId);
                expect(balance.toBigInt()).to.be.equal(0);
            });

            it("Should fail if user tries to remove from a team that you don't belong to", async function () {
                // add a new wallet
                await expect(
                    myContract
                        .connect(bob)
                        .removeFromTeam(alice.address, tokenId)
                ).to.be.revertedWith("Ownable: caller is not the owner");
            });
        });
    });

    describe("Other Functions", function () {
        it("Owner should add a wallet to a pre-existing team", async function () {
            // add to team
            expect(await myContract.supportsInterface(0x01ffc9a7)).to.equal(
                true
            );

            expect(await myContract.owner()).to.equal(
                owner.address
            );

            await myContract.transferOwnership(alice.address)

            expect(await myContract.owner()).to.equal(
                alice.address
            );

            await myContract.connect(alice).transferOwnership(owner.address)

            await myContract.selfDestruct();

            await expect(
                myContract
                    .balanceOf(alice.address, tokenId)
            ).to.be.reverted;
        });
    });
});
