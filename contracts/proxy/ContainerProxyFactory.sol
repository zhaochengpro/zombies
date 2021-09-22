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

    // Create new contianer
    function createContainer() public onlyOwner returns (address) {
        ContainerProxy container = new ContainerProxy(
            _beacon,
            67,
            _msgSender()
        );
        _counterFactory.createCounter(address(container), 67);
        container.setCounter(address(_counterFactory));

        return address(container);
    }
}

contract ContainerProxy is MinimalBeaconProxy, Ownable {
    uint256 public zombieAmount;

    ContainerManager private _containerManager;

    FrameCounterFactory public _counterFactory;

    mapping(uint8 => uint256) private _eachGradeAmount;

    event Fallback(address indexed container, uint256 number);

    constructor(
        address beacon,
        uint256 zombieAmount_,
        address containerManager_
    ) MinimalBeaconProxy(beacon) {
        zombieAmount = zombieAmount_;
        _containerManager = ContainerManager(containerManager_);
        _initEachGradeAmountMapping();
    }

    modifier onlyManager() {
        require(_msgSender() == address(_containerManager));
        _;
    }

    function getEachGradeAmount(uint8 grade) public view returns (uint256) {
        return _eachGradeAmount[grade];
    }

    function decrementGradeAmount(uint8 gradeId) public onlyManager {
        require(_eachGradeAmount[gradeId] > 0);
        _eachGradeAmount[gradeId]--;
    }

    function setCounter(address counter_) public onlyOwner {
        _counterFactory = FrameCounterFactory(counter_);
    }

    function containerManager()
        internal
        view
        virtual
        returns (ContainerManager)
    {
        return _containerManager;
    }

    function notifyCreateNewContainer() internal virtual {
        ContainerManager manager = containerManager();
        manager.receiveCreateNewContainerNotification(address(this));
    }

    function notifyToCloseContainer() internal virtual {
        ContainerManager manager = containerManager();
        manager.receiveCloseContainerNotification(address(this));
    }

    // function beforePurchaseFunc(string memory funcStr) internal virtual {
    //     bytes memory funcBytes = abi.encodePacked(funcStr);
    //     uint256 dataLen = funcBytes.length;
    //     if (keccak256(_msgData()[:dataLen]) == keccak256(funcBytes)) {
            
    //     }
    // }

    // function _beforeFallback() internal virtual override {
    //     if (_counterFactory.isMaxed(address(this))) {
    //         notifyToCloseContainer();
    //     } else if (
    //         zombieAmount - _counterFactory.current(address(this)) <= 7
    //     ) {
    //         notifyCreateNewContainer();
    //     } else {
    //         beforePurchaseFunc("purchaseCard(uint8)");
    //     }
    // }

    function _initEachGradeAmountMapping() private {
        _eachGradeAmount[0] = 25;
        _eachGradeAmount[1] = 22;
        _eachGradeAmount[2] = 10;
        _eachGradeAmount[3] = 6;
        _eachGradeAmount[4] = 4;
    }
}

contract ContainerManager is Ownable {
    mapping(uint256 => ContainerProxy) private containerMap;
    ContainerProxy[] private _containers;
    ContainerProxyFactory private _containerFactory;
    ZombieLogic private _zombieLogic;

    // Mapping from container address to isActive
    mapping(address => bool) private _isActive;

    constructor(address zombieLogic_, address beacon) {
        _containerFactory = new ContainerProxyFactory(beacon);
        _zombieLogic = ZombieLogic(zombieLogic_);
        _containers = new ContainerProxy[](135);
    }

    function isActive(address container) public view returns (bool) {
        return _isActive[container];
    }

    function beforePurchaseCard(uint8 number, address cotainerId) public payable {
        // address containerAddr = address(containerMap[cotainerId]);
        address containerAddr = cotainerId;
        require(containerAddr != address(0x0));

        (bool success, ) = containerAddr.call(
            abi.encodeWithSignature(
                "purchaseCard(uint8)",
                number
            )
        );
        require(success, "purchase card not success");
    }

    function getEachGradeAmount(address container, uint8 grade)
        public
        view
        returns (uint256)
    {
        require(isActive(container));
        return ContainerProxy(payable(container)).getEachGradeAmount(grade);
    }

    // Get active contianers at present
    function getActiveContainers()
        public
        view
        onlyOwner
        returns (address[] memory)
    {
        require(_zombieLogic.isPreSaleEnded(), "pre-sale is not ended");
        uint256 len = _containers.length;
        address[] memory activeContainers = new address[](10);
        uint256 activeIndex = 0;

        for (uint256 i = 0; i < len; i++) {
            address container = address(_containers[i]);
            if (isActive(container)) {
                if (activeIndex < 10) {
                    activeContainers[activeIndex] = container;
                    activeIndex++;
                } else {
                    break;
                }
            }
        }

        return activeContainers;
    }

    // Receive the notification that create new container from every container;
    function receiveCreateNewContainerNotification(address container) public {
        require(isActive(container), "Container was disactive");
        _createNewContainer();
    }

    function receiveCloseContainerNotification(address container) public {
        require(isActive(container), "Container was closed");

        _isActive[container] = false;
        (bool success, ) = container.call(
            abi.encodeWithSignature("setActive(bool)", false)
        );

        require(success);
    }

    function decrementGradeAmount(address container, uint8 grade) public {
        require(isActive(container));
        console.log(container, grade);
        ContainerProxy(payable(container)).decrementGradeAmount(grade);
    }

    function receivePresaleEnded(address zombieLogic) public {
        require(address(_zombieLogic) == address(zombieLogic));

        for (uint256 i = 0; i < 10; i++) {
            _createNewContainer();
        }
    }

    function _createNewContainer() private {
        require(_zombieLogic.isPreSaleEnded(), "pre-sale is not ended");

        address container = _containerFactory.createContainer();
        _containers.push(ContainerProxy(payable(container)));
        containerMap[_containers.length] = ContainerProxy(payable(container));
        _isActive[container] = true;
    }
}
