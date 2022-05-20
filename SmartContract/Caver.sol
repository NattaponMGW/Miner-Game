// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "GetRandom.sol";

contract Caver is ERC721Enumerable, GetRandom {
    address private _owner;

    using Strings for uint256;

    string public baseUri = "https://raw.githubusercontent.com/NattaponMGW/Miner-Game/main/Images/c-";
    string public baseExtension = ".png";

    uint256 public nftId;

    mapping(uint256 => uint256) public nftType; // random from 1 - 5
    mapping(uint256 => uint256) public nftStrength; // total strength
    mapping(uint256 => uint256) public nftSpace; //available space
    mapping(uint256 => uint256) public nftSharpens;
    mapping(uint256 => uint256) public nftFoods;

    mapping(uint256 => uint256) public nftRank;
    mapping(uint256 => uint256) public nftLevel;
    mapping(uint256 => uint256) public nftExp;
    mapping(uint256 => uint256) public nftLifeTime;

    // list of added pickaxe & backpack;
    // CaverId => list of equipped item's id
    mapping(uint256 => uint256[]) public equippedPickaxe; // [12, 15, 56, 256]
    mapping(uint256 => uint256[]) public equippedBackpack;

    // address => in whitelist or not
    mapping(address => bool) public whiteLists;

    constructor() ERC721("Caver", "CAVER") {
        _owner = msg.sender;

    }

    // ------------------------------------------------------------------------------

    function addPickaxe(uint256 caverId, uint256 pickaxeId, uint256 str) public onlyWhitelist{
        require(nftSpace[caverId] > 0, "Available space is zero.");
        nftSpace[caverId]--;
        
        nftStrength[caverId] += str;
        equippedPickaxe[caverId].push(pickaxeId);
    }

    function addBackpack(uint256 caverId, uint256 backpackId, uint256 space) public onlyWhitelist{
        nftSpace[caverId] += space;
        equippedBackpack[caverId].push(backpackId);
    }
    
    function addSharpens(uint256 caverId, uint256 value) public onlyWhitelist{
        nftSharpens[caverId] += value;
    }
    
    function addFoods(uint256 caverId, uint256 value) public onlyWhitelist{
        nftFoods[caverId] += value;
    }
    
    function useSharpens(uint256 caverId, uint256 value) public onlyWhitelist{
        nftSharpens[caverId] -= value;
    }
    
    function useFoods(uint256 caverId, uint256 value) public onlyWhitelist{
        nftFoods[caverId] -= value;
    }

    function setRank(uint256 caverId, uint256 value) public onlyWhitelist{
        nftRank[caverId] = value;
    }
    
    function setLevel(uint256 caverId, uint256 value) public onlyWhitelist{
        nftLevel[caverId] = value;
    }
    
    function addExp(uint256 caverId, uint256 value) public onlyWhitelist{
        nftExp[caverId] += value;
    }
    
    function setLifeTime(uint256 caverId, uint256 value) public onlyWhitelist{
        nftLifeTime[caverId] = value;
    }

    function useLifeTime(uint256 caverId, uint256 value) public onlyWhitelist{
        nftLifeTime[caverId] -= value;
    }

    function PickaxeEquippedAmount(uint256 caverId) public view returns(uint256) {
        return equippedPickaxe[caverId].length;
    }
    // ------------------------------------------------------------------------------
    function mintCaver(address receiver) public onlyWhitelist {
        require(msg.sender != address(0));

        nftId++; // start from no. 1
        while ( _exists(nftId)) nftId++;

        // Mint here
        nftType[nftId] = _random(nftId); // random from 1 -5

        _mint(receiver, nftId);

    }

    // -------------------------------------------------------------------------------------------
    function setbaseUri(string memory input) public onlyWhitelist{
        baseUri = input;
    }

    function setBaseExtension(string memory input) public onlyWhitelist{
        baseExtension = input;
    }
    
    function tokenUri(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Uri query for nonexistent token");

        string memory _baseUri = baseUri;
        return bytes(_baseUri).length > 0 
            ? string(abi.encodePacked(_baseUri, nftType[tokenId].toString(), baseExtension))
            : "";
    }
    // -------------------------------------------------------------------------------------------

    function _random(uint256 x) internal view returns(uint256){
        uint256 randomNumber = random(x); // random value from 0 - 999
        uint256 itemType;

        if (randomNumber < 200){
            itemType = 5;
        }else if (randomNumber < 400){
            itemType = 4;
        }else if (randomNumber < 600){
            itemType = 3;
        }else if (randomNumber < 800){
            itemType = 2;
        }else {
            itemType = 1;
        }
        return (itemType);
    }

     modifier onlyWhitelist() {
        require(msg.sender == _owner || whiteLists[msg.sender], "Ownable: caller is not the owner or whitelisted"); // Or
        _;
    }

    function setWhitelists (address add, bool isWhitelist) public onlyWhitelist {
        whiteLists[add] = isWhitelist;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721) {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId) || whiteLists[msg.sender], "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
}