import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

describe("Greeter deploy", () => {
  var contract: Contract

  beforeEach(async () => {
    const Contract = await ethers.getContractFactory("Greeter");
    contract = await Contract.deploy("MyContract");
    await contract.deployed();
  })

  it("should return its name", async () => {
    expect(await contract.greet()).to.equal("MyContract")
  })

  it("should change its name when requested", async () => {
    contract.setGreeting("Another Contract").then(async () => {
      expect(await contract.greet()).to.equal("Another Contract")
    })
  })
})