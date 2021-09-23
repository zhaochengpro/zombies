pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import 'hardhat/console.sol';

contract ZombieToken is ERC721 {
    using Counters for Counters.Counter;

    struct Zombie {
        uint8 grade;
        string name;
    }

    Counters.Counter private _tokenId;

    address private _zombieLogicAddress;

    // Mapping from tokenId to zombie
    mapping(uint256 => Zombie) zombies;

    constructor(address zombieLogicAddress_) ERC721("Zombie Token", "ZTK") {
        _zombieLogicAddress = zombieLogicAddress_;
    }

    modifier onlyLogicContract() {
        require(
            _msgSender() == _zombieLogicAddress,
            "Zombie: only logic contract"
        );
        _;
    }

    function mint(address to, uint8 level) public {
        Zombie memory newZombie = Zombie(level, "");
        uint256 currentTokenId = _tokenId.current();
        zombies[currentTokenId] = newZombie;
        _mint(to, currentTokenId);
        _tokenId.increment();
    }

    function currentSupply() public view onlyLogicContract returns (uint256) {
        return _tokenId.current() + 1;
    }

    function getZombieGradeByTokenId(uint256 tokenId)
        public
        view
        onlyLogicContract
        returns (uint8)
    {
        return zombies[tokenId].grade;
    }

    function changeSZombieName(string memory newName) public {}
}
