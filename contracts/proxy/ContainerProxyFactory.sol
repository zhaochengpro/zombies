pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./MinimalBeaconProxy.sol";
import "../zombie/ZombieLogic.sol";
import "../utils/FrameCounterFactory.sol";

function bytesToUint(bytes memory b) pure returns (uint256) {
    uint256 number;
    for (uint256 i = 0; i < b.length; i++) {
        number = number + uint8(b[i]) * (2**(8 * (b.length - (i + 1))));
    }
    return number;
}

contract ContainerProxyFactory is Ownable {
    address private _beacon;

    constructor(address beacon_) {
        _beacon = beacon_;
    }

    // Create new contianer
    function createContainer() public onlyOwner returns (address) {
        ContainerProxy container = new ContainerProxy(
            _beacon,
            67,
            _msgSender()
        );
        return address(container);
    }
}

contract ContainerProxy is MinimalBeaconProxy, Ownable {
    uint256 public zombieAmount;

    ContainerManager private _containerManager;

    bool private isNewContainer;

    // mapping(uint8 => uint256) private _eachGradeAmount;

    event Fallback(address indexed container, uint256 number);

    constructor(
        address beacon,
        uint256 zombieAmount_,
        address containerManager_
    ) MinimalBeaconProxy(beacon) {
        zombieAmount = zombieAmount_;
        _containerManager = ContainerManager(containerManager_);
        // _initEachGradeAmountMapping();
    }

    modifier onlyManager() {
        require(_msgSender() == address(_containerManager));
        _;
    }

    // function getEachGradeAmount(uint8 grade) public view returns (uint256) {
    //     return _eachGradeAmount[grade];
    // }

    function decrementGradeAmount() public onlyManager {
        require(zombieAmount > 0);
        zombieAmount--;
    }

    function containerManager()
        internal
        view
        virtual
        returns (ContainerManager)
    {
        return _containerManager;
    }

    function notifyCreateNewContainer() internal virtual returns (address) {
        ContainerManager manager = containerManager();
        return manager.receiveCreateNewContainerNotification(address(this));
    }

    function notifyToCloseContainer() internal virtual {
        ContainerManager manager = containerManager();
        manager.receiveCloseContainerNotification(address(this));
    }

    function beforePurchaseFunc(string memory funcStr)
        internal
        virtual
        returns (uint8 number, address buyer)
    {
        bytes memory funcBytes = abi.encodePacked(funcStr);
        uint256 len = funcBytes.length;

        if (keccak256(_msgData()[:len]) == keccak256(funcBytes)) {
            uint256 numberLen = _msgData().length - len - 20;
            number = uint8(bytesToUint(_msgData()[len:len + numberLen]));
            bytes memory buyerBytes = _msgData()[len + numberLen:];

            assembly {
                buyer := mload(add(buyerBytes, 20))
            }
        }
    }
    
    // function _fallback() internal override {
    //     _delegate(_implementation())
    // }

    function _delegate(address implementation) internal override {
        _delegatePurchaseCard(implementation);
    }

    function _delegatePurchaseCard(address implementation) internal {
        (uint8 number, address buyer) = beforePurchaseFunc(
            "purchaseCard(uint8,address)"
        );

        int256 spreadAmount = int256(zombieAmount) - int8(number);
        if (spreadAmount == 0) {
            _callPurchaseCard(implementation, number, buyer);
            notifyToCloseContainer();
            console.log(0);
        } else if (spreadAmount < 0) {
            console.log(1);
            _callPurchaseCard(implementation, uint8(zombieAmount), buyer);
            notifyToCloseContainer();
            if (number - zombieAmount > 0) {
                address newContainer = notifyCreateNewContainer();
                _handleSpreadAmount(newContainer, spreadAmount);
            }
        } else if (spreadAmount <= 7 && spreadAmount > 0 && !isNewContainer) {
            notifyCreateNewContainer();
            isNewContainer = true;
            _callPurchaseCard(implementation, number, buyer);
        } else {
            console.log(2);
             _callPurchaseCard(implementation, number, buyer);
        }
    }

    function _callPurchaseCard(address implementation_, uint8 number_, address buyer_) internal {
        (bool success, ) = implementation_.call{value: msg.value}(
            abi.encodeWithSignature(
                "purchaseCard(uint8,address)",
                number_,
                buyer_
            )
        );
        require(success, "_delegate failed");
    }

    function _handleSpreadAmount(address newContainer, int256 spread_) private {
        ContainerManager manager = containerManager();
        uint8 number = 0;
        for (int256 i = spread_; i < 0; i++) {
            number++;
        }
        manager.beforePurchaseCard(number, newContainer);
    }

    // function _initEachGradeAmountMapping() private {
    //     _eachGradeAmount[0] = 25;
    //     _eachGradeAmount[1] = 22;
    //     _eachGradeAmount[2] = 10;
    //     _eachGradeAmount[3] = 6;
    //     _eachGradeAmount[4] = 4;
    // }
}

contract ContainerManager is Ownable {
    mapping(uint256 => ContainerProxy) private containerMap;

    ContainerProxy[] private _containers;
    ContainerProxyFactory private _containerFactory;
    FrameCounterFactory private _counterFactory;

    ZombieLogic private _zombieLogic;

    // Mapping from container address to isActive
    mapping(address => bool) private _isActive;

    constructor(address zombieLogic_, address beacon) {
        _containerFactory = new ContainerProxyFactory(beacon);
        _counterFactory = new FrameCounterFactory();
        _zombieLogic = ZombieLogic(zombieLogic_);
        _containers = new ContainerProxy[](135);
    }

    function isActive(address container) public view returns (bool) {
        return _isActive[container];
    }

    function beforePurchaseCard(uint8 number, address containerId)
        public
        payable
    {
        address containerAddr = containerId;
        require(containerAddr != address(0x0));

        if (!_isValidContainer(containerId)) {
            revert("container is invalid");
        }

        _incrementContainerCounter(containerId, number);
        // console.log(_msgSender());

        (bool success, ) = containerAddr.call{value: msg.value}(
            abi.encodePacked(
                "purchaseCard(uint8,address)",
                number,
                _msgSender()
            )
        );
        require(success, "purchase card not success");
    }

    // function getEachGradeAmount(address container, uint8 grade)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     require(isActive(container));
    //     return ContainerProxy(payable(container)).getEachGradeAmount(grade);
    // }

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
    function receiveCreateNewContainerNotification(address container)
        public
        returns (address)
    {
        require(isActive(container), "Container was disactive");
        return _createNewContainer();
    }

    // Receive the notification that create close a container from every container;
    function receiveCloseContainerNotification(address container) public {
        require(isActive(container), "Container was closed");

        _isActive[container] = false;
        (bool success, ) = container.call(
            abi.encodeWithSignature("setActive(bool)", false)
        );

        require(success);
    }

    function receivePresaleEnded(address zombieLogic) public {
        require(address(_zombieLogic) == address(zombieLogic));

        for (uint256 i = 0; i < 10; i++) {
            _createNewContainer();
        }
    }

    function _createNewContainer() private returns (address) {
        require(_zombieLogic.isPreSaleEnded(), "pre-sale is not ended");

        address container = _containerFactory.createContainer();
        _containers.push(ContainerProxy(payable(container)));
        _counterFactory.createCounter(container, 67);
        containerMap[_containers.length] = ContainerProxy(payable(container));
        _isActive[container] = true;

        return container;
    }

    function _isValidContainer(address container_) private view returns (bool) {
        require(_isActive[container_], "container was closed");

        return !_counterFactory.isMaxed(container_);
    }

    function _incrementContainerCounter(address containerId, uint8 number)
        private
    {
        ContainerProxy container = ContainerProxy(payable(containerId));
        for (uint8 i = 0; i < number; i++) {
            _counterFactory.increment(containerId);
            container.decrementGradeAmount();
        }
    }
}
