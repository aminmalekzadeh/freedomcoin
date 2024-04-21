const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FreedomCoin", function () {
  async function deployTokenFixture() {
    const [owner, otherAccount, receiver] = await ethers.getSigners();
    const FreedomCoin = await ethers.getContractFactory("FreedomCoin");
    const token = await FreedomCoin.deploy(owner.address);

    return { token, owner, otherAccount, receiver };
  }

  describe("Whitelist and Blacklist", function () {
    it("Should add and confirm an account in the whitelist", async function () {
      const { token, owner, receiver } = await loadFixture(deployTokenFixture);

      await token.addToWhitelist(receiver.address);
      expect(await token.isWhitelisted(receiver.address)).to.be.true;
    });

    it("Should remove an account from the whitelist", async function () {
      const { token, receiver } = await loadFixture(deployTokenFixture);

      await token.addToWhitelist(receiver.address);
      await token.removeFromWhitelist(receiver.address);
      expect(await token.isWhitelisted(receiver.address)).to.be.false;
    });

    it("Should add and confirm an account in the blacklist", async function () {
      const { token, otherAccount } = await loadFixture(deployTokenFixture);

      await token.addToBlacklist(otherAccount.address);
      expect(await token.isBlacklisted(otherAccount.address)).to.be.true;
    });

    it("Should remove an account from the blacklist", async function () {
      const { token, otherAccount } = await loadFixture(deployTokenFixture);

      await token.addToBlacklist(otherAccount.address);
      await token.removeFromBlacklist(otherAccount.address);
      expect(await token.isBlacklisted(otherAccount.address)).to.be.false;
    });

    it("Should prevent a blacklisted account from receiving tokens", async function () {
      const { token, owner, otherAccount } = await loadFixture(deployTokenFixture);

      await token.addToBlacklist(otherAccount.address);
      await expect(token.transfer(otherAccount.address, 100))
        .to.be.revertedWith("Recipient is blacklisted");
    });

    it("Should allow a whitelisted account to receive tokens", async function () {
      const { token, owner, receiver } = await loadFixture(deployTokenFixture);

      await token.addToWhitelist(receiver.address);
      await expect(token.transfer(receiver.address, 100)).to.emit(token, "Transfer")
        .withArgs(owner.address, receiver.address, 100);
    });

    it("Should prevent non-whitelisted accounts from receiving tokens", async function () {
      const { token, owner, otherAccount } = await loadFixture(deployTokenFixture);

      await expect(token.transfer(otherAccount.address, 100))
        .to.be.revertedWith("Recipient is not whitelisted");
    });
  });
});
