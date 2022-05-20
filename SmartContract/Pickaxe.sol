// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "GetRandom.sol";

contract Pickaxe is ERC721Enumerable, GetRandom {
    address private _owner;

    using Strings for uint256;

    string public baseUri = "https://raw.githubusercontent.com/NattaponMGW/Miner-Game/main/Images/p-";
    string public baseExtension = ".jpg";

    uint256 public nftId;

    mapping(uint256 => uint256) public nftLevel;

    // Item (nftId) ==> strength of that item
    mapping(uint256 => uint256) public nftStr;
    

    // Item (nftId) ==> has been equipped or not
    mapping(uint256 => bool) public nftEquipped;

    // address => in whitelist or not
    mapping(address => bool) public whiteLists;

    constructor() ERC721("Pickaxe", "PX") {
        _owner = msg.sender;
    }
    
    // ------------------------------------------------------------------------------

    function tokenUri(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Uri query for nonexistent token");

        string memory _baseUri = baseUri;
        return bytes(_baseUri).length > 0 
            ? string(abi.encodePacked(_baseUri, nftLevel[tokenId].toString(), baseExtension))
            : "";
    }


    function mintPickaxe(address receiver, uint256 amount) public onlyWhitelist {
        require(amount > 0, "Amount to mint is zero.");
        require(msg.sender != address(0));

        for (uint256 i = 1; i <= amount; i++){
            _mintPickaxe(receiver); // mint each item
        }
        
    }

    function _mintPickaxe(address receiver) internal {
        nftId++; // start from no. 1
        while ( _exists(nftId)) nftId++;

        (nftLevel[nftId], nftStr[nftId]) = _random(nftId);
        nftEquipped[nftId] = false;

        _mint(receiver, nftId);

    }

    function equippedItem(uint256 itemId, bool equipped) public onlyWhitelist{
        nftEquipped[itemId] = equipped;
    }

    function setItemStr(uint256 itemId, uint256 str) public onlyWhitelist{
        require (str >= 15 && str <= 250, "Strengh exceed requirement");
        nftStr[itemId] = str;
    }

    function setbaseUri(string memory input) public onlyWhitelist{
        baseUri = input;
    }

    function setBaseExtension(string memory input) public onlyWhitelist{
        baseExtension = input;
    }

    function _random(uint256 x) internal view returns(uint256, uint256){
        uint256 randomNumber = random(x); // random value from 0 - 999
        uint256 level;
        uint256 strength;

        if (randomNumber < 10){
            level = 5;
            strength = 200 +( (55 * random(x)) / 999);
        }else if (randomNumber < 60){ // from 10 to 59
            level = 4;
            strength = 150 +( (50 * random(x) )/ 999);

        }else if (randomNumber < 210){
            level = 3;
            strength = 100 +( (50 * random(x)) / 999);

        }else if (randomNumber < 560){
            level = 2;
            strength = 50 +( (50 * random(x)) / 999);

        }else {
            level = 1;
            strength = 15 +( (35 * random(x)) / 999);

        }

        return (level, strength);

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
    ) public override(ERC721) { //, IERC721
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId) || whiteLists[msg.sender], "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
}