// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pickaxe.sol";
import "./Backpack.sol";
import "./Caver.sol";
import "./Token.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Gameplay is Ownable{
    Caver public caver;
    Backpack public backpack;
    Pickaxe public pickaxe = Pickaxe(0x5A86858aA3b595FD6663c2296741eF4cd8BC4d01);
    Token public token;

    address public gamePool = 0xb8DE0C06A0d55584e7DA4148F352Ed9fF4595367;

    function MintItem(uint256 choose, uint256 amount) public {
        // 1 = Pickaxe
        // 2 = Backpack
        // 3 = Caver

        if (choose == 1){
            //Pay Token for item

            pickaxe.mintPickaxe(msg.sender, amount);
        }else if (choose == 2){
            //Pay Token for item

            backpack.mintBackpack(msg.sender, amount);

        }else if (choose == 3){
            //Pay Token for item

            amount = 1;
            caver.mintCaver(msg.sender);
        }
    }

    function EquipPickaxe(uint256[] memory itemId, uint256 caverId) public { // 1. list of pickaxes-id, caverId
        require(msg.sender != address(0));
        require(caver.ownerOf(caverId) == msg.sender, "Not your Caver.");
        for (uint256 i = 0; i < itemId.length; i++){
            require(pickaxe.ownerOf(itemId[i]) == msg.sender, "Not your Pickaxe.");
        }

        for (uint256 i = 0; i < itemId.length; i++){
            uint256 pickaxeStr = pickaxe.nftStr(itemId[i]);
            caver.addPickaxe(caverId, itemId[i], pickaxeStr);   
            
            pickaxe.transferFrom(msg.sender, gamePool, itemId[i]);
        }
    }

    function EquipBackpack(uint256[] memory itemId, uint256 caverId) public {
        require(msg.sender != address(0));
        require(caver.ownerOf(caverId) == msg.sender, "Not your Caver.");
        for (uint256 i = 0; i < itemId.length; i++){
            require(backpack.ownerOf(itemId[i]) == msg.sender, "Not your Pickaxe.");
        }

        for (uint256 i = 0; i < itemId.length; i++){
            uint256 backpackSpace = backpack.nftSpace(itemId[i]);
            caver.addBackpack(caverId, itemId[i], backpackSpace);   
            
            backpack.transferFrom(msg.sender, gamePool, itemId[i]);
        }
    }


    // function _mintPickaxe(uint256 amount) public onlyOwner {
    //     pickaxe.mintPickaxe(msg.sender, amount);
    // }
    
}