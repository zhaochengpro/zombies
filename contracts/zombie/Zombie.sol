pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ZombieToken is ERC721 {

    struct Zombie {
        uint8 grade;
        string name;
    }

    enum ZombieGrade { DLEVEL,  CLEVEL, BLEVEL, ALEVEL, SLEVEL }

    address private _zombieLogicAddress;

    // Mapping from tokenId to zombie
    mapping(uint256 => Zombie) zombies;

    constructor(address zombieLogicAddress_) ERC721("Zombie Token", "ZTK") {
        _zombieLogicAddress = zombieLogicAddress_;
    }

    modifier onlyLogicContract {
        require(_msgSender() == _zombieLogicAddress, "Zombie: only logic contract");
        _;
    }

    function mint(address to, uint256 tokenId) public onlyLogicContract {
        _mint(to, tokenId);
    }
}

