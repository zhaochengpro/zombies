pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function mint(address to, uint256 tokenId) external;
}

contract ZombieLogic is Ownable {
    IERC721 private _zombieToken;

    modifier hasZombieToken {
        require(address(_zombieToken) != address(0x0), "ZombieLogic:_zombieToken no set");
        _;
    }

    function setZombieToken(address zombieToken_) public onlyOwner {
        _zombieToken = IERC721(zombieToken_);
    }

    function mint(address to, uint256 tokenId) public {
        _zombieToken.mint(to, tokenId);
    }
}