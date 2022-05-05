// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "GetRandom.sol";

contract Backpack is ERC721Enumerable, Ownable, GetRandom {
    constructor() ERC721("Backpack", "BP") {}

    using Strings for uint256;

    string public baseURI = "https://raw.githubusercontent.com/NattaponMGW/Miner-Game/main/Images/b-";
    string public baseExtension = ".jpg";

    uint256 public nftId;

    mapping(uint256 => uint256) public nftLevel;

    // Item (nftId) ==> strength of that item
    mapping(uint256 => uint256) public nftSpace;
    

    // Item (nftId) ==> has been equipped or not
    mapping(uint256 => bool) public nftEquipped;

    // address => in whitelist or not
    mapping(address => bool) public whiteLists;

    // ------------------------------------------------------------------------------

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _baseURI = baseURI;
        return bytes(_baseURI).length > 0 
            ? string(abi.encodePacked(_baseURI, nftLevel[tokenId].toString(), baseExtension))
            : "";
    }


    function mintBackpack(address receiver, uint256 amount) public onlyOwner {
        require(amount > 0, "Amount to mint is zero.");
        require(msg.sender != address(0));

        for (uint256 i = 1; i <= amount; i++){
            _mintBackpack(receiver); // mint each item
        }
        
    }

    function _mintBackpack(address receiver) internal {
        nftId++; // start from no. 1
        while ( _exists(nftId)) nftId++;

        (nftLevel[nftId], nftSpace[nftId]) = _random(nftId);
        nftEquipped[nftId] = false;

        _mint(receiver, nftId);

    }

    function equippedItem(uint256 itemId, bool equipped) public onlyOwner{
        nftEquipped[itemId] = equipped;
    }

    function setItemSpace(uint256 itemId, uint256 space) public onlyOwner{
        require(space > 0 && space <= 5, "Space exceed requirement");
        nftSpace[itemId] = space;
    }

    function setbaseURI(string memory input) public onlyOwner{
        baseURI = input;
    }

    function setBaseExtension(string memory input) public onlyOwner{
        baseExtension = input;
    }

    function _random(uint256 x) internal view returns(uint256, uint256){
        uint256 randomNumber = random(x); // random value from 0 - 999
        uint256 level;
        uint256 space;

        if (randomNumber < 10){
            level = 5;
            space = level;
        }else if (randomNumber < 60){ // from 10 to 59
            level = 4;
            space = level;

        }else if (randomNumber < 210){
            level = 3;
            space = level;

        }else if (randomNumber < 560){
            level = 2;
            space = level;

        }else {
            level = 1;
            space = level;

        }

        return (level, space);

    }

     modifier onlyOwner() override {
        require(owner() == _msgSender() || whiteLists[msg.sender], "Ownable: caller is not the owner or whitelisted"); // Or
        _;
    }

    function setWhitelists (address add, bool isWhitelist) public onlyOwner {
        whiteLists[add] = isWhitelist;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId) || whiteLists[msg.sender], "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
}