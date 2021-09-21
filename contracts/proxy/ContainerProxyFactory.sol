pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MinimalBeaconProxy.sol";
import "../zombie/ZombieLogic.sol";
import "../utils/FrameCounterFactory.sol";

contract ContainerProxyFactory is Ownable {
    FrameCounterFactory private _counterFactory;

    address private _beacon;

    constructor(address beacon_) {
        _counterFactory = new FrameCounterFactory();
        _beacon = beacon_;
    }

    // Create a wilderness for pre-sale
    function createWilderness() public onlyOwner returns (address) {
        Wilderness wilderness = new Wilderness(_beacon, 820, _msgSender());
        address counter = _counterFactory.createCounter(
            address(wilderness),
            // 820
            2
        );
        wilderness.setCounter(counter);

        return address(wilderness);
    }

    // Create new contianer
    function createContainer() public onlyOwner returns (address) {
        ContainerProxy container = new ContainerProxy(
            _beacon,
            67,
            _msgSender()
        );
        address counter = _counterFactory.createCounter(address(container), 67);
        container.setCounter(counter);

        return address(container);
    }
}

contract ContainerProxy is MinimalBeaconProxy, Ownable {
    uint256 public zombieAmount;

    ContainerManager private _containerManager;

    FrameCounterContract public _counter;

    bool public isActive;

    mapping(uint8 => uint256) private _eachGradeAmount;

    constructor(
        address beacon,
        uint256 zombieAmount_,
        address containerManager_
    ) MinimalBeaconProxy(beacon) {
        zombieAmount = zombieAmount_;
        _containerManager = ContainerManager(containerManager_);
        _initEachGradeAmountMapping();
    }

    function getEachGradeAmount(uint8 grade) public view returns (uint256) {
        return _eachGradeAmount[grade];
    }

    function setActive(bool isActive_) external virtual onlyOwner {
        isActive = isActive_;
    }

    function setCounter(address counter_) external virtual onlyOwner {
        _counter = FrameCounterContract(counter_);
    }

    function counter() internal view virtual returns (FrameCounterContract) {
        return _counter;
    }

    function containerManager()
        internal
        view
        virtual
        returns (ContainerManager)
    {
        return _containerManager;
    }

    function beforePurchaseFunc(string memory funcStr) internal virtual {
        bytes memory funcBytes = abi.encodePacked(funcStr);
        uint256 dataLen = funcBytes.length;
        if (keccak256(_msgData()[:dataLen]) == keccak256(funcBytes)) {
            counter().increment(address(this));
        }
    }

    function notifyCreateNewContainer() internal virtual {
        ContainerManager manager = containerManager();
        manager.receiveCreateNewContainerNotification(address(this));
    }

    function notifyToCloseContainer() internal virtual {
        ContainerManager manager = containerManager();
        manager.receiveCloseContainerNotification(address(this));
    }

    function beforePurchaseCard(uint8 number) public {
        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSignature("purchaseCard(uint8, address)", number, address(this))
        );
        require(success, "purchase card not success");
    }

    function _beforeFallback() internal virtual override {
        if (counter().isMaxed(address(this))) {
            notifyToCloseContainer();
        } else if (zombieAmount - counter().current() <= 7) {
            notifyCreateNewContainer();
        } else {
            beforePurchaseFunc("purchaseCard(uint8)");
        }
    }

    function _initEachGradeAmountMapping() private {
        _eachGradeAmount[0] = 25;
        _eachGradeAmount[1] = 22;
        _eachGradeAmount[2] = 10;
        _eachGradeAmount[3] = 6;
        _eachGradeAmount[4] = 4;
    }
}

contract Wilderness is ContainerProxy {
    constructor(
        address beacon,
        uint256 zombieAmount_,
        address containerManager_
    ) ContainerProxy(beacon, zombieAmount_, containerManager_) {}

    function _beforeFallback() internal override {
        if (counter().isMaxed(address(this))) {
            // prepared to create a new container, if the rest of zombie amount less than 7
            // Notify container manager to  create a new cointainer
            notifyCreateNewContainer();
        } else {
            beforePurchaseFunc("purchasePreSaleZombie(uint256)");
        }
    }
}

contract ContainerManager is Ownable {
    Wilderness public wilderness;

    ContainerProxy[] private _containers;
    ContainerProxyFactory private _containerFactory;
    ZombieLogic private _zombieLogic;

    // Mapping from container address to isActive
    mapping(address => bool) private _isActive;

    constructor(address zombieLogic_, address beacon) {
        _containerFactory = new ContainerProxyFactory(beacon);
        _zombieLogic = ZombieLogic(zombieLogic_);
        _containers = new ContainerProxy[](135);

        //create wilderness for pre-sale
        if (
            !_zombieLogic.isPreSaleEnded() &&
            _zombieLogic.presaleAmount() == 820
        ) {
            address wildernessAddr = _containerFactory.createWilderness();
            wilderness = Wilderness(payable(wildernessAddr));
        }
    }

    function getWilderness() public view onlyOwner returns (address) {
        require(address(wilderness) != address(0x0));
        require(!_zombieLogic.isPreSaleEnded(), "pre-sale is ended");
        return address(wilderness);
    }

    // Get active contianers at present
    function getActiveContainers()
        public
        view
        onlyOwner
        returns (address[] memory)
    {
        require(_zombieLogic.isPreSaleEnded(), "pre-sale not ended");
        uint256 len = _containers.length;
        address[] memory activeContainers = new address[](10);

        for (uint256 i = 0; i < len; i++) {
            address container = address(_containers[i]);
            if (_isActive[container]) {
                activeContainers[i] = container;
            }
        }

        return activeContainers;
    }

    // Receive the notification that create new container from every container;
    function receiveCreateNewContainerNotification(address container) public {
        require(_isActive[container], "Container was disactive");
        _createNewContainer();
    }

    function receiveCloseContainerNotification(address container) public {
        require(_isActive[container], "Container was closed");
        _isActive[container] = false;
        ContainerProxy(payable(container)).setActive(false);
    }

    function _createNewContainer() private onlyOwner {
        address container = _containerFactory.createContainer();
        _containers.push(ContainerProxy(payable(container)));
        _isActive[container] = true;
        ContainerProxy(payable(container)).setActive(true);
    }
}
