// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pickaxe.sol";
import "./Backpack.sol";
import "./Caver.sol";
import "./Token.sol";
import "./GetRandom.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Gameplay is Ownable, GetRandom{
    Caver public caver = Caver(0x09943Fa8DD32C76f7b880627a0F6af73e8f5A595);
    Backpack public backpack = Backpack(0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8);
    Pickaxe public pickaxe = Pickaxe(0x5A86858aA3b595FD6663c2296741eF4cd8BC4d01);
    Token public token;

    address public gamePool = 0xb8DE0C06A0d55584e7DA4148F352Ed9fF4595367;

    // constructor(Caver caverAddress, Backpack backpackAddress, Pickaxe pickaxeAddress){
    //     caver = Caver(caverAddress);
    //     backpack = Backpack(backpackAddress);
    //     pickaxe = Pickaxe(pickaxeAddress);
    // }

    // player => all Reward
    mapping(address => uint256) public myReward;
    // player => last Mined (timestamp)
    mapping(uint256 => uint256) public lastMined;
    // player => last claim reward (timestamp)
    mapping(address => uint256) public lastClaimReward;

    uint256 public waitMinePeriod = 3 minutes; //           24 hours
    uint256 public waitClaimRewardPeriod = 60 minutes; //   10 days
    uint256 public claimRewardFee = 30; // 30% of total reward

    uint256 public rewardPerLevel = 359; //Must devide by 100

    // --------------------------------------------------------------------------------
    function ClaimReward() public {
        require (msg.sender != address(0));
        require (myReward[msg.sender] > 0, "Player has no reward");

        // Pass waiting period
        uint256 rewardToClaim;
        rewardToClaim = CalculateReward(msg.sender);

        TransferReward(rewardToClaim, msg.sender);

        myReward[msg.sender] = 0;

        lastClaimReward[msg.sender] = block.timestamp;
    }

    function CalculateReward(address player) public view returns(uint256) {
        uint256 reward;
        uint256 claimWithNoFeeTime = lastClaimReward[player] + waitClaimRewardPeriod;

        if(block.timestamp >= claimWithNoFeeTime){
            reward = myReward[player];
        }else {
            // fee 30% period
            uint256 feePeriod = claimWithNoFeeTime - lastClaimReward[player];
            // Time remains
            uint256 timeRemains = feePeriod - (claimWithNoFeeTime - block.timestamp);
            // calculate fee % by time remains
            uint256 fee = (claimRewardFee * timeRemains) / feePeriod;
            reward = ( myReward[player] * ((100 - claimRewardFee) + fee) ) / 100;
        }

       return (reward);
    }
    
    function TransferReward(uint256 amount, address receiver) internal {
        token.transferFrom(gamePool, receiver, amount);
    } 

    // --------------------------------------------------------------------------------

    function Mine(uint256 caverId, uint256 level) public{
        require (msg.sender != address(0));
        require (caver.ownerOf(caverId) == msg.sender, "Not your Caver");

        //Sharpens amount
        uint256 sharpensNeed = caver.PickaxeEquippedAmount(caverId);
        require (caver.nftSharpens(caverId) >= sharpensNeed, "Not enough sharpens");

        //Foods amount
        uint256 foodsNeed = ( (rewardPerLevel * 5) / 10 ) * level;
        require (caver.nftFoods(caverId) >= foodsNeed, "Not enough foods");

        //Strength
        require (caver.nftStrength(caverId) > (level * 100), "Not enough Caver's strength");

        //Pass waiting period
        require (PassMineWaitingPeriod(caverId), "Caver is in waiting period");

        //Conditions
        require (!claimRewardFirst(msg.sender), "Claim your reward before the next Mine");

        if (myReward[msg.sender] == 0){
            //set this mine to lastClaimReward
            lastClaimReward[msg.sender] = block.timestamp;
        }

        // Calculate Reward
        uint256 reward;
        reward = TokenReward( reward * level );
        uint256 result;
        uint256 successNumber = random(caverId);
        if (successNumber >= 300) { // 70% Seccess Rate
            result = reward;
        }else {
            result = 0;
        }

        if (result > 0 ){
            // Give Reward
            myReward[msg.sender] += result;
        }

        // Use sharpens & foods
        caver.useSharpens(caverId, sharpensNeed);
        caver.useFoods(caverId, foodsNeed);

        lastMined[caverId] = block.timestamp;
    }

    function claimRewardFirst(address player) public view returns(bool){
        if(CalculateReward(player) >= myReward[player])
            return (true);
        else    
            return (false);
    }

    function PassMineWaitingPeriod(uint256 caverId) public view returns(bool){
        if(block.timestamp > lastMined[caverId] + waitMinePeriod)
            return (true);
        else
            return (false);
    }

    function BuyConsumable(uint256 caverId, uint256 sharpenAmount, uint256 foodAmount) public {
        require(sharpenAmount >= 0, "Sharpen amount less than zero");
        require(foodAmount >= 0, "Food amount less than zero");

        // Pay token for consumable

        if (sharpenAmount > 0){
            caver.addSharpens(caverId, sharpenAmount);
        }
        if (foodAmount > 0){
            caver.addFoods(caverId, foodAmount);
        }
    }

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

    function TokenReward(uint256 reward) public pure returns(uint256){
        reward = (reward * 10 ** 18) / 100;
        return (reward);
    }


    // function _mintPickaxe(uint256 amount) public onlyOwner {
    //     pickaxe.mintPickaxe(msg.sender, amount);
    // }
    
}