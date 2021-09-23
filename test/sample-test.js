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

    const container01 = new ethers.Contract(containers[0], Container.interface.fragments, owner);
    await containerManager.connect(account).beforePurchaseCard(5, container01.address, { value: utils.parseEther("1") })
    const zombieAmount = await container01.zombieAmount();
    expect(zombieAmount.toString(10)).equal("62");
    const tokenBalance = await zombie.balanceOf(account.address);
    expect(tokenBalance.toString(10)).equal('5');
  })
  it("Test new container", async () => {
    const [owner, account] = await ethers.getSigners();
    const Zombie = await ethers.getContractFactory("ZombieToken");
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

    const container01 = new ethers.Contract(containers[0], Container.interface.fragments, owner);
    for (let i = 0; i < 12; i++) {
      await containerManager.connect(account).beforePurchaseCard(5, container01.address, { value: utils.parseEther("1") })
    }
    const zombieAmount = await container01.zombieAmount();
    expect(zombieAmount.toString(10)).equal("7");
    const tokenBalance = await zombie.balanceOf(account.address);
    expect(tokenBalance.toString(10)).equal("60");
  })
  it("Test to new container when the amount of zombie euqal zero", async () => {
    const [owner, account] = await ethers.getSigners();
    const Zombie = await ethers.getContractFactory("ZombieToken");
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
    const container01 = new ethers.Contract(containers[0], Container.interface.fragments, owner);
    for (let i = 0; i < 12; i++) {
      await containerManager.connect(account).beforePurchaseCard(5, container01.address, { value: utils.parseEther("1") })
    }
    await containerManager.connect(account).beforePurchaseCard(3, container01.address, { value: utils.parseEther("1") })
    await containerManager.connect(account).beforePurchaseCard(1, container01.address, { value: utils.parseEther("1") })
    await containerManager.connect(account).beforePurchaseCard(3, container01.address, { value: utils.parseEther("1") })
    const zombieAmount = await container01.zombieAmount();
    expect(zombieAmount.toString(10)).equal("0");
    const tokenBalance = await zombie.balanceOf(account.address);
    expect(tokenBalance.toString(10)).equal("67");
    const newContainers = await containerManager.getActiveContainers();
    expect(newContainers[0]).equal("0x0000000000000000000000000000000000000000");
    expect(newContainers.length).equal(11);
  })
  it("Test to new container when the amount of zombie equal less than 7", async () => {
    const [owner, account] = await ethers.getSigners();
    const Zombie = await ethers.getContractFactory("ZombieToken");
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
    const container01 = new ethers.Contract(containers[0], Container.interface.fragments, owner);
    for (let i = 0; i < 12; i++) {
      await containerManager.connect(account).beforePurchaseCard(5, container01.address, { value: utils.parseEther("1") })
    }
    await containerManager.connect(account).beforePurchaseCard(3, container01.address, { value: utils.parseEther("1") })
    const zombieAmount = await container01.zombieAmount();
    expect(zombieAmount.toString(10)).equal("4");
    const tokenBalance = await zombie.balanceOf(account.address);
    expect(tokenBalance.toString(10)).equal("63");
    const newContainers = await containerManager.getActiveContainers();
    expect(newContainers.length).equal(11);
  })
  it("Test to new container when the amount of zombie greater then the rest of zombie amount ",
    async () => {
      const [owner, account] = await ethers.getSigners();
      const Zombie = await ethers.getContractFactory("ZombieToken");
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
      console.log(containers);
      const container01 = new ethers.Contract(containers[0], Container.interface.fragments, owner);
      for (let i = 0; i < 12; i++) {
        await containerManager.connect(account).beforePurchaseCard(5, container01.address, { value: utils.parseEther("1") })
      }
      console.log("test",containerManager.address, account.address);
      await containerManager.connect(account).beforePurchaseCard(3, container01.address, { value: utils.parseEther("1") })
      await containerManager.connect(account).beforePurchaseCard(1, container01.address, { value: utils.parseEther("1") })
      await containerManager.connect(account).beforePurchaseCard(5, container01.address, { value: utils.parseEther("1") })
      const zombieAmount = await container01.zombieAmount();
      expect(zombieAmount.toString(10)).equal("0");
      const tokenBalance = await zombie.balanceOf(account.address);
      expect(tokenBalance.toString(10)).equal("69");
      const newContainers = await containerManager.getActiveContainers();
      
    })
});
