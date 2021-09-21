const { zeroPad } = require("@ethersproject/bytes");
const { expect } = require("chai");
const { utils } = require("ethers");
const { ethers } = require("hardhat");

describe("Zombies", function () {
  it("msgsender", async () => {
    const Zombie = await ethers.getContractFactory("ZombieToken");
    const ZombieLogic = await ethers.getContractFactory("ZombieLogic");
    const zombieLogic = await ZombieLogic.deploy();
    zombieLogic.deployed();
    const zombie = await Zombie.deploy(zombieLogic.address);
    zombie.deployed()
    console.log(zombieLogic.address)
    await zombieLogic.setZombieToken(zombie.address);
  })
  it("preSale", async () => {
    const Zombie = await ethers.getContractFactory("ZombieToken");
    const ZombieLogic = await ethers.getContractFactory("ZombieLogic");
    const zombieLogic = await ZombieLogic.deploy();
    zombieLogic.deployed();
    const zombie = await Zombie.deploy(zombieLogic.address);
    zombie.deployed()
    await zombieLogic.setZombieToken(zombie.address);
    await zombieLogic.purchasePreSaleZombie(20, {value:utils.parseEther('2')})
    const grade0 = await zombieLogic.getZombieGrade(0);
    const grade1 = await zombieLogic.getZombieGrade(2);
    const grade2 = await zombieLogic.getZombieGrade(3);
    const grade3 = await zombieLogic.getZombieGrade(4);
    const grade4 = await zombieLogic.getZombieGrade(5);
    const grade5 = await zombieLogic.getZombieGrade(6);
    const presaleAmount = await zombieLogic.presaleAmount();
    console.log(grade0, grade1, grade2, grade3, grade4, grade5, presaleAmount.toString(10))
  })
  it("purchasePresaleZombie or card", async () => {
    const Zombie = await ethers.getContractFactory("ZombieToken");
    const ZombieLogic = await ethers.getContractFactory("ZombieLogic");
    const zombieLogic = await ZombieLogic.deploy();
    zombieLogic.deployed();
    const zombie = await Zombie.deploy(zombieLogic.address);
    zombie.deployed()
    await zombieLogic.setZombieToken(zombie.address);
    // await zombieLogic.purchaseCard(2);
    // await zombieLogic.purchaseCard(1);
  })
  it("all function", async () => {
    const Zombie = await ethers.getContractFactory("ZombieToken");
    // console.log(Zombie)
    const ZombieLogic = await ethers.getContractFactory("ZombieLogic");
    const ContainerManager = await ethers.getContractFactory("ContainerManager");
    const ZombieBeacon = await ethers.getContractFactory("ZombieBeacon");
    const zombieLogic = await ZombieLogic.deploy();
    zombieLogic.deployed();
    const zombie = await Zombie.deploy(zombieLogic.address);
    zombie.deployed()
    await zombieLogic.setZombieToken(zombie.address);
    const zombieBeacon = await ZombieBeacon.deploy(zombieLogic.address);
    zombieBeacon.deployed();
    const containerManager = await ContainerManager.deploy(zombieLogic.address, zombieBeacon.address)
    containerManager.deployed();
    const wildernessAddr  = await containerManager.getWilderness();
    const Wilderness = await ethers.getContractFactory("Wilderness")
    const wilderness = new ethers.Contract(wildernessAddr, Wilderness.interface.fragments);
    wilderness.purchaseCard()
  })
});
