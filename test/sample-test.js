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
    await zombieLogic.purchasePreSaleZombie(20, { value: utils.parseEther('2') })
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
    await zombieLogic.purchasePreSaleZombie(2, { value: utils.parseEther('1') });
    const presaleAmount = await zombieLogic.presaleAmount();
    console.log(presaleAmount.toString(10));
  })
  it("Test begain to create container when pre-sale is ended", async () => {
    //   const Zombie = await ethers.getContractFactory("ZombieToken");
    //   // console.log(Zombie)
    //   const ZombieLogic = await ethers.getContractFactory("ZombieLogic");
    //   const ContainerManager = await ethers.getContractFactory("ContainerManager");
    //   const ZombieBeacon = await ethers.getContractFactory("ZombieBeacon");
    //   const zombieLogic = await ZombieLogic.deploy();
    //   zombieLogic.deployed();
    //   const zombie = await Zombie.deploy(zombieLogic.address);
    //   zombie.deployed()
    //   await zombieLogic.setZombieToken(zombie.address);
    //   const zombieBeacon = await ZombieBeacon.deploy(zombieLogic.address);
    //   zombieBeacon.deployed();
    //   const containerManager = await ContainerManager.deploy(zombieLogic.address, zombieBeacon.address)
    //   containerManager.deployed();
    //   await zombieLogic.setContainerManager(containerManager.address);
    //   await zombieLogic.setPresaleEnded(true);
    //   const containers = await containerManager.getActiveContainers();
    //   console.log(containers);
  })
  it("Test purchase card by one container", async () => {
    const [owner, account] = await ethers.getSigners();
    const Zombie = await ethers.getContractFactory("ZombieToken");
    // console.log(Zombie)
    const ZombieLogic = await ethers.getContractFactory("ZombieLogic");
    const ContainerManager = await ethers.getContractFactory("ContainerManager");
    const ZombieBeacon = await ethers.getContractFactory("ZombieBeacon");
    const Container = await ethers.getContractFactory("ContainerProxy");
    const zombieLogic = await ZombieLogic.deploy();
    zombieLogic.deployed();
    const zombie = await Zombie.deploy(zombieLogic.address);
    zombie.deployed()
    await zombieLogic.setZombieToken(zombie.address);
    const zombieBeacon = await ZombieBeacon.deploy(zombieLogic.address);
    zombieBeacon.deployed();
    const containerManager = await ContainerManager.deploy(zombieLogic.address, zombieBeacon.address)
    containerManager.deployed();
    await zombieLogic.setContainerManager(containerManager.address);
    await zombieLogic.setPresaleEnded(true);
    const containers = await containerManager.getActiveContainers();
    // console.log(containers);
    console.log("account",await zombieLogic.getContainerManager())
    console.log("account1",zombie.address);
    await containerManager.connect(account).beforePurchaseCard(5, containers[0], { value: utils.parseEther("10")});
    
    // const aAmount = await container01.connect(account).getEachGradeAmount(0);
    // const aAmount1 = await container01.connect(account).getEachGradeAmount(1);
    // const aAmount2 = await container01.connect(account).getEachGradeAmount(2);
    // const aAmount3 = await container01.connect(account).getEachGradeAmount(3);
    // const aAmount4 = await container01.connect(account).getEachGradeAmount(4);
    // console.log(aAmount.toString(10),aAmount1.toString(10),aAmount2.toString(10),aAmount3.toString(10),aAmount4.toString(10));
  })
});
