pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
    function mint(address to, uint8 level) external;
    function getZombieGradeByTokenId(uint256 tokenId)
        external
        view
        returns (uint8);
    function currentSupply() external view returns (uint256);
}

contract ZombieLogic is Ownable {
    IERC721 private _zombieToken;

    event BuyZombies(address indexed to, uint256 numbers);

    bool private _isRevealed;
    uint256 private _preSaleStartTime;
    uint256 private _preSaleEndTime;

    uint256 public constant _MAX_SUPPLY = 9180;
    uint256 public  presaleAmount = 820;

    uint256 private constant _ZOMBIEPRICE = 0.1 ether;
    uint256 private constant _CARDPRICE = 0.01 ether;
    enum ZombieGrade {
        ELEVEL,
        DLEVEL,
        CLEVEL,
        BLEVEL,
        ALEVEL,
        SLEVEL
    }

    constructor() {
        _preSaleStartTime = block.timestamp;
        _preSaleEndTime = block.timestamp + 432000; // 5 days
    }

    modifier hasZombieToken() {
        require(
            address(_zombieToken) != address(0x0),
            "ZombieLogic:_zombieToken no set"
        );
        _;
    }

    function setZombieToken(address zombieToken_) public onlyOwner {
        _zombieToken = IERC721(zombieToken_);
    }

    /**
        @notice People can purchase the pre-sale zombie
     */
    function purchasePreSaleZombie(uint256 zombeNumber)
        public
        payable
        hasZombieToken
    {
        require(!_isPreSaleEnded(), "pre-sale is ended");
        require(msg.value >= _ZOMBIEPRICE * zombeNumber);

        _mintGeneralZombies(zombeNumber);
    }

    /**
        @notice People can purchase the card of game
        @dev The number of card must be 1 or 3 or 5
        pre-sale must be not ended yet
     */
    function purchaseCard(uint8 cardNumber) public payable hasZombieToken {
        require(
            cardNumber == 1 || cardNumber == 3 || cardNumber == 5,
            "the card number of purchase must be 1 or 3 or 5"
        );
        require(_isPreSaleEnded(), "pre-sale is not ended");
        require(
            _zombieToken.currentSupply() + cardNumber < _MAX_SUPPLY, 
            "the remainder of zombie not enough"
        );
        require(msg.value >= _CARDPRICE * cardNumber, "value not enough");

        _mintGeneralZombies(cardNumber);
    }

    // @undo Should _msgSender() replace with winer
    function mintSZombie() public hasZombieToken {
        _zombieToken.mint(_msgSender(), uint8(ZombieGrade.SLEVEL));
        emit BuyZombies(_msgSender(), 1);
    }

    function getZombieGrade(uint256 tokenId)
        public
        view
        hasZombieToken
        returns (uint8)
    {
        return _zombieToken.getZombieGradeByTokenId(tokenId);
    }

    function _isPreSaleEnded() private view returns (bool) {
        return
            block.timestamp >= _preSaleEndTime ||
            presaleAmount == 0;
    }

    /**
        @notice mint general zombie (including mint pre-sale zombie)
     */
    function _mintGeneralZombies(uint256 zombieNumber_) private hasZombieToken {
        
        if (!_isPreSaleEnded()) {
            // Randomly mint zombie A, B, C
            _mintGeneralZombiesByGrade(
                zombieNumber_,
                uint8(ZombieGrade.SLEVEL)
            );
            presaleAmount -= zombieNumber_;
        } else {
            // Randomly mint zombie A, B, C, D, E
            _mintGeneralZombiesByGrade(
                zombieNumber_,
                uint8(ZombieGrade.SLEVEL) + 1
            );
        }

        emit BuyZombies(_msgSender(), zombieNumber_);
    }

    function _mintGeneralZombiesByGrade(uint256 zombieNumber_, uint8 level_)
        private
    {
        for (uint256 i = 0; i < zombieNumber_; i++) {
            uint8 randomLevel = uint8(
                uint256(
                    keccak256(abi.encodePacked(block.timestamp, msg.sender, i))
                ) % level_
            );

            // if random range is A to C, it will jump DLEVEL and ELEVEL
            if (
                level_ == uint8(ZombieGrade.SLEVEL) &&
                randomLevel < uint8(ZombieGrade.CLEVEL)
            ) {
                randomLevel += 2;
            }

            _zombieToken.mint(_msgSender(), randomLevel);
        }
    }
}