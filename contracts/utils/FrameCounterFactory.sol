// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @author Simon Tian
/// @title Counter factory for frame counters
contract FrameCounterFactory is Ownable {

    mapping(address => FrameCounterContract) _counters;

    constructor() {}

    modifier onlyCounterExist(address boardAddr) {
        require(_counters[boardAddr] != FrameCounterContract(address(0)), "Non-Existing Counter");
        _;
    }

    modifier onlyCounterNotExist(address boardAddr) {
        require(_counters[boardAddr] == FrameCounterContract(address(0)), "Existing Counter");
        _;
    }

    function exists(address boardAddr) public view returns (bool) {
        if (_counters[boardAddr] != FrameCounterContract(address(0))) {
            return true;
        } else {
            return false;
        }
    }

    function createCounter(address boardAddr, uint16 maxVal)
        public
        onlyOwner
        onlyCounterNotExist(boardAddr)
    {
        _counters[boardAddr] = new FrameCounterContract(boardAddr, maxVal);
    }
    
    function increment(address boardAddr)
        public
        onlyCounterExist(boardAddr)
        onlyOwner
    {
        _counters[boardAddr].increment(boardAddr);
    }

    function current(address boardAddr)
        public
        view
        onlyCounterExist(boardAddr)
        returns (uint16)
    {
        return _counters[boardAddr].current();
    }

    function isMaxed(address boardAddr)
        public
        view
        onlyCounterExist(boardAddr)
        returns (bool)
    {
        return _counters[boardAddr].isMaxed(boardAddr);
    }
}

/*
    The reason of using this contractFactory is when tokenIds are generated,
    there is no guarantee that frameIds can be all generated for one board with
    no interruptions.Therefore, board address based counter is needed to address
    this issue.
*/

contract FrameCounterContract {

    Counter private counter;
    address private boardAddr;
    address private factory;
    uint16 private immutable maxVal;

    struct Counter {
        uint16 value; // default: 0
    }

    /*
        Events & Errors
    */
    error LimitExceeded(
        uint16 current,
        uint16 maxVal
    );

    constructor(address boardAddr_, uint16 maxVal_) {
        boardAddr = boardAddr_;
        factory = msg.sender;
        maxVal = maxVal_;
    }

    modifier onlyOwner(address caller) {
        require(caller == boardAddr, "Only Owner.");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Only Factory.");
        _;
    }

    function current() public view returns (uint16) {
        return counter.value;
    }

    function increment(address caller)
        public
        onlyFactory
        onlyOwner(caller)
    {
        counter.value++;
        if (current() > maxVal)
            revert LimitExceeded(current(), maxVal);
    }

    function isMaxed(address caller)
        public
        view
        onlyFactory
        onlyOwner(caller)
        returns (bool)
    {
        return current() == maxVal;
    }
}
