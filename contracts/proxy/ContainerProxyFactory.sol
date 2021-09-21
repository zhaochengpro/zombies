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

    function createWilderness() public onlyOwner returns (address) {
        Wilderness wilderness = new Wilderness(_beacon, 820);
        _counterFactory.createCounter(address(wilderness), 820);
        return address(wilderness);
    }
    
    function createContainer() public onlyOwner returns (address) {
        ContainerProxy container = new ContainerProxy(_beacon, 67);
        return address(container);
    }
}

contract ContainerProxy is MinimalBeaconProxy, Ownable {
    uint256 public zombieAmount;

    constructor(address beacon, uint256 zombieAmount_)
        MinimalBeaconProxy(beacon)
    {
        zombieAmount = zombieAmount_;
    }
}

contract Wilderness is ContainerProxy {
    constructor(address beacon, uint256 zombieAmount_)
        ContainerProxy(beacon, zombieAmount_)
    {}
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

        //create wilderness
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

    function getActiveContainers() public view onlyOwner returns (address[] memory) {
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
    
    function _createNewContainer() private onlyOwner {
        address container = _containerFactory.createContainer();
        _containers.push(ContainerProxy(payable(container)));
    }
}
