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

describe("🚩 Full Popp Employer Verification Voting Flow", function () {
    this.timeout(120000);

    describe("Popp Verification Voting", function () {
        // `beforeEach` will run before each test, re-deploying the contract every
        // time. It receives a callback, which can be async.
        beforeEach(async function () {
            // deploy contract
            const TokenMockFactory = await ethers.getContractFactory("TokenMock");
            const PoppEmployerVoting = await ethers.getContractFactory("PoppEmployerBadgeVoting");
            this.token = await TokenMockFactory.deploy();
            this.contract = await PoppEmployerVoting.deploy(this.token.address);
            await this.contract
                .setProposalCost(100);

            await this.contract
                .setVoteMinBalance(100);

            [owner, alice, bob, connie] = await ethers.getSigners();
            // starting balance for alice
            this.token.connect(owner).transfer(alice.address, 100);
            this.token.connect(owner).transfer(bob.address, 100);
        });

        describe("propose()", function () {
            it("Should be able to propose a new employer badge", async function () {
                await this.token.connect(alice).approve(this.contract.address, 100)

                // propose a new badge
                await this.contract
                    .connect(alice)
                    .propose("test.json");

                // check uri is the same for the new wallet token
                let myProposal = await this.contract
                    .connect(alice)
                    .getMyProposal();
                expect(myProposal.uri).to.equal("test.json");
                let proposal = await this.contract
                    .connect(alice)
                    .getProposal(1);
                expect(proposal.uri).to.equal("test.json");


                expect(
                    await this.token
                        .balanceOf(alice.address)
                ).to.equal(0);

                expect(
                    await this.token
                        .balanceOf(this.contract.address)
                ).to.equal(100);

                // check uri is the same for the new wallet token
                let yesVotes = await this.contract
                    .getVotes(1, true);
                let noVotes = await this.contract
                    .getVotes(1, false);
                // yes votes
                expect(yesVotes.length).to.equal(0);
                // no votes
                expect(noVotes.length).to.equal(0);
                // only one proposal allowed
                await expect(
                    this.contract
                        .connect(alice)
                        .propose("test.json")
                ).to.be.revertedWith("You already have a proposal");
            });

            it("Should not be able to propose once you hold an employers badge", async function () {
                await this.token.connect(alice).approve(this.contract.address, 100)

                // alice has an employers badge
                await this.contract
                    .mintNewBadge(alice.address);

                await expect(
                    this.contract
                        .connect(alice)
                        .propose("test.json")
                ).to.be.revertedWith("You already have an employer badge");

                // ensure no tokens were transferred
                expect(
                    await this.token
                        .balanceOf(alice.address)
                ).to.equal(100);
            });
        });

        describe("vote()", function () {
            it("Should be able to vote on a proposal", async function () {
                await this.token.connect(owner).approve(this.contract.address, 100)

                // propose a new badge
                await this.contract
                    .propose("test.json");

                // alice needs a badge to vote
                await this.contract.mintNewBadge(alice.address);

                await this.contract
                    .connect(alice)
                    .vote(1, true);

                let yesVotes = await this.contract
                    .getVotes(1, true);
                let noVotes = await this.contract
                    .getVotes(1, false);
                // yes votes
                expect(yesVotes.length).to.equal(1);
                // no votes
                expect(noVotes.length).to.equal(0);
                expect(yesVotes[0]).to.equal(alice.address.toString());
                // proposal doesn't exist
                await expect(
                    this.contract
                        .connect(connie)
                        .vote(999999, false)
                ).to.be.revertedWith("Proposal does not exist");
                // you can only vote once
                await expect(
                    this.contract
                        .connect(alice)
                        .vote(1, false)
                ).to.be.revertedWith("You already voted");
                // you need to hold POPP tokens to vote
                await this.contract.mintNewBadge(connie.address);
                await expect(
                    this.contract
                        .connect(connie)
                        .vote(1, false)
                ).to.be.revertedWith("You need to have some at least 100 POPP tokens to vote");
                // you can't vote on your own proposal
                await expect(
                    this.contract
                        .connect(owner)
                        .vote(1, false)
                ).to.be.revertedWith("You cannot vote on your own proposal");

                // you need to be a verified employer to vote
                await expect(
                    this.contract
                        .connect(bob)
                        .vote(1, false)
                ).to.be.revertedWith("You must have an employer badge to vote");
            });
        });

        describe("conclude()", function () {
            it("Should be able to conclude a successful proposal", async function () {
                await this.token.connect(alice).approve(this.contract.address, 100)
                await this.contract
                    .connect(owner)
                    .setProposalTtl(0);

                // propose a new badge
                await this.contract
                    .connect(alice)
                    .propose("test.json");

                await this.contract.mintNewBadge(bob.address);

                await this.contract
                    .connect(bob)
                    .vote(1, true);

                expect(
                    await this.token
                        .balanceOf(alice.address)
                ).to.equal(0);

                await this.contract
                    .conclude(1);

                expect(
                    await this.token
                        .balanceOf(alice.address)
                ).to.equal(0);

                expect(
                    await this.token
                        .balanceOf(bob.address)
                ).to.equal(200);
            });

            it("Should be able to conclude an unsuccessful proposal", async function () {
                await this.token.connect(alice).approve(this.contract.address, 100)
                await this.contract
                    .connect(owner)
                    .setProposalTtl(0);

                // propose a new badge
                await this.contract
                    .connect(alice)
                    .propose("test.json");

                // bob needs a badge to vote
                await this.contract.mintNewBadge(bob.address);
                // bob votes no
                await this.contract
                    .connect(bob)
                    .vote(1, false);
                // check alice's balance
                expect(
                    await this.token
                        .balanceOf(alice.address)
                ).to.equal(0);
                // check bob's balance
                expect(
                    await this.token
                        .balanceOf(bob.address)
                ).to.equal(100);

                await this.contract
                    .conclude(1);
                // alice's balance should be the same
                expect(
                    await this.token
                        .balanceOf(alice.address)
                ).to.equal(0);
                // bob should receive 100 POPP tokens
                expect(
                    await this.token
                        .balanceOf(bob.address)
                ).to.equal(200);
            });

            it("Should not be able to conclude a proposal that hasn't reached its ttl", async function () {
                await this.token.connect(alice).approve(this.contract.address, 100)
                await this.contract
                    .connect(owner)
                    .setProposalTtl(0);

                // propose a new badge
                await this.contract
                    .connect(alice)
                    .propose("test.json");
                // bob needs a badge to vote
                await this.contract.mintNewBadge(bob.address);
                // bob votes no
                await this.contract
                    .connect(bob)
                    .vote(1, false);
                // check alice's balance
                expect(
                    await this.token
                        .balanceOf(alice.address)
                ).to.equal(0);
                // check bob's balance
                expect(
                    await this.token
                        .balanceOf(bob.address)
                ).to.equal(100);

                await this.contract
                    .conclude(1);
                // alice's balance should be the same
                expect(
                    await this.token
                        .balanceOf(alice.address)
                ).to.equal(0);
                // bob should receive 100 POPP tokens
                expect(
                    await this.token
                        .balanceOf(bob.address)
                ).to.equal(200);
            });
        });

    });
});
