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

    address private _nextNewContainer;

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

    function notifyCreateNewContainer() internal virtual returns (address) {
        return
            _containerManager.receiveCreateNewContainerNotification(
                address(this)
            );
    }

    function notifyToCloseContainer() internal virtual {
        _containerManager.receiveCloseContainerNotification(address(this));
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

    function _delegate(address implementation) internal override {
        _delegatePurchaseCard(implementation);
    }

    function _delegatePurchaseCard(address implementation) internal {
        (uint8 number, address buyer) = beforePurchaseFunc(
            "purchaseCard(uint8,address)"
        );
        // console.log(number, buyer);
        // Calaulate the excess amount of the last purchase in this container
        int256 spreadAmount = int256(zombieAmount) - int8(number);

        if (spreadAmount == 0) {
            // notify container manager to create a new container and close this container
            _callPurchaseCard(implementation, number, buyer);
            notifyToCloseContainer();
        } else if (spreadAmount < 0) {
            // Notify container manager to create a new container
            // At the same time, to purchase the spread amount of token in new container
            _callPurchaseCard(implementation, uint8(zombieAmount), buyer);

            if (_nextNewContainer == address(0x0)) {
                _nextNewContainer = notifyCreateNewContainer();
            }

            
            (bool success, ) = address(_containerManager).call{value: 200000000000000000}(
                abi.encodeWithSignature(
                    "purchaseCardOnlyContainer(uint8,address,address)",
                    uint8(number - zombieAmount),
                    _nextNewContainer,
                    buyer
                )
            );
            require(success, "purchaseCardOnlyContainer failed");
            // After purchase new card, to close last container
            notifyToCloseContainer();
        } else if (
            spreadAmount <= 7 &&
            spreadAmount > 0 &&
            _nextNewContainer == address(0x0)
        ) {
            // Notify container mananger to create a new container,
            // if the rest of zombie amount is less than 7
            _nextNewContainer = notifyCreateNewContainer();
            _callPurchaseCard(implementation, number, buyer);
        } else {
            _callPurchaseCard(implementation, number, buyer);
        }
    }

    function _callPurchaseCard(
        address implementation_,
        uint8 number_,
        address buyer_
    ) internal {
        (bool success, ) = implementation_.call{value: msg.value}(
            abi.encodeWithSignature(
                "purchaseCard(uint8,address)",
                number_,
                buyer_
            )
        );
        require(success, "_delegate failed");
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
    address[] public activeContainers;
    mapping(address => uint256) activeContainersIndex;

    constructor(address zombieLogic_, address beacon) {
        _containerFactory = new ContainerProxyFactory(beacon);
        _counterFactory = new FrameCounterFactory();
        _zombieLogic = ZombieLogic(zombieLogic_);
    }

    function isActive(address container) public view returns (bool) {
        return _isActive[container];
    }

    function beforePurchaseCard(uint8 number, address container)
        public
        payable
    {
        _handleBeforePurchaseCard(number, container, _msgSender());
    }

    function purchaseCardOnlyContainer(
        uint8 number,
        address container,
        address lastBuyer
    ) public payable {
        _handleBeforePurchaseCard(number, container, lastBuyer);
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
        delete activeContainers[activeContainersIndex[container]];
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
        ContainerProxy containerProxy = ContainerProxy(payable(container));
        _containers.push(containerProxy);
        _counterFactory.createCounter(container, 67);
        containerMap[_containers.length] = containerProxy;
        _isActive[container] = true;
        activeContainersIndex[container] = activeContainers.length;
        activeContainers.push(container);
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

    function _handleBeforePurchaseCard(
        uint8 number,
        address container,
        address buyer
    ) private {
        if (!_isValidContainer(container)) {
            revert("container is invalid");
        }
        console.log(address(this), container, isActive(address(this)));
        // if the sender is the owner, this requirement is not required
        require(
            isActive(_msgSender()) ||
                number == 1 ||
                number == 3 ||
                number == 5,
            "The card number of purchase must be 1 or 3 or 5"
        );

        require(container != address(0x0));
        (bool success, ) = container.call{value: msg.value}(
            abi.encodePacked("purchaseCard(uint8,address)", number, buyer)
        );

        require(success, "purchase card not success");

        _incrementContainerCounter(container, number);
    }
}
