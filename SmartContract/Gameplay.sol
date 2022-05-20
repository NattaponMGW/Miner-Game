// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Pickaxe.sol";
import "./Backpack.sol";
import "./Caver.sol";
import "./Token.sol";
import "./GetRandom.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Gameplay is Ownable{

    event mined(address player, uint256 caverId, uint256 reward);


    Caver public caver = Caver(0xbf2911094b147cEe54AA9E54C91F61E2A5E3A1CA);
    Backpack public backpack = Backpack(0xAf995528d81dDB9E7eA72c85E41CF0d32FF82Aa5);
    Pickaxe public pickaxe = Pickaxe(0x56a0c49923cF4FFd53621F71FE0801e5444b78ac);
    Token public token = Token(0x5e6C055331122A6EA75b39cC0b5F4D6E36F9866f);
    GetRandom public getRandom = GetRandom(0xED38F7494Aef3BC7f20C4a768A42D9A15C449433);

    address public gamePool = 0xb8DE0C06A0d55584e7DA4148F352Ed9fF4595367;

    // player => all Reward
    mapping(address => uint256) public myReward;
    // player => last Mined (timestamp)
    mapping(uint256 => uint256) public lastMined;
    // player => last claim reward (timestamp)
    mapping(address => uint256) public lastClaimReward;

    uint256 public waitMinePeriod = 3 minutes; //           24 hours
    uint256 public waitClaimRewardPeriod = 60 minutes; //   10 days
    uint256 public claimRewardFee = 30; // 30% of total reward

    uint256 public rewardPerLevel = 359; // token = ( rewardPerLevel * 10 ** 18) / 100

    uint256 public caverPrice = 19;     // token = (price * 10 ** 18)
    uint256 public backpackPrice = 19;  // token = (price * 10 ** 18)
    uint256 public pickaxePrice = 19;   // token = (price * 10 ** 18)

    uint256 public sharpenPrice = 1;    // token = (price * 10 ** 18)
    uint256 public foodPrice = 1;       // token = (price / 1000) * 10 ** 18

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
    
    // --------------------------------------------------------------------------------
    function ReceiveToken(uint amount) public {
        // player must give allowance to Gameplay contract first;
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Player : Insufficient allowance");
        require(token.balanceOf(msg.sender) >= amount, "Player : Insufficient balance");

        token.transferFrom(msg.sender, gamePool, amount);
    }
    
    function TransferReward(uint256 amount, address receiver) internal {
        uint256 allowance = token.allowance(gamePool, address(this));
        require(allowance >= amount, "Game's Pool : Insufficient allowance");
        require(token.balanceOf(gamePool) >= amount, "Game's Pool : Insufficient balance");

        token.transferFrom(gamePool, receiver, amount);
    } 

    // --------------------------------------------------------------------------------

    function TestMine(uint256 caverId, uint256 level, bool emitEvent)public onlyOwner{
        uint256 reward;
        reward = toToken( rewardPerLevel * level ) / 100;
        uint256 result;
        uint256 successNumber = getRandom.random(caverId);
        if (successNumber >= 300) { // 70% Seccess Rate
            result = reward;
        }else {
            result = 0;
        }

        if (result > 0 ){
            // Give Reward

            myReward[msg.sender] += result;
        }

        if (emitEvent){
            emit mined(msg.sender, caverId, result);
        }
    }

    function TestRandom(uint256 freeInt) public view onlyOwner returns(uint256) {
        uint256 returnRandom = getRandom.random(freeInt);
        return (returnRandom);
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
        reward = toToken( rewardPerLevel * level ) / 100;
        uint256 result;
        uint256 successNumber = getRandom.random(caverId);
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
        
        emit mined(msg.sender, caverId, result);
    }

    function claimRewardFirst(address player) public view returns(bool){
        if(CalculateReward(player) >= myReward[player] && myReward[player] != 0)
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
        ReceiveToken(toToken(sharpenAmount * sharpenPrice) + ( toToken(foodAmount * foodPrice) / 1000) );

        if (sharpenAmount > 0){
            caver.addSharpens(caverId, sharpenAmount);
        }
        if (foodAmount > 0){
            caver.addFoods(caverId, foodAmount);
        }
    }

    function MintItem(uint256 choose, uint256 amount) public {
        // 1 = Caver
        // 2 = Backpack
        // 3 = Pickaxe
        
        if (choose == 1){
            //Pay Token for item
            ReceiveToken(toToken(caverPrice));

            amount = 1;
            caver.mintCaver(msg.sender);
        }else if (choose == 2){
            //Pay Token for item
            ReceiveToken(toToken(backpackPrice));

            backpack.mintBackpack(msg.sender, amount);

        }else if(choose == 3){
            ReceiveToken(toToken(pickaxePrice));

            pickaxe.mintPickaxe(msg.sender, amount);
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

    function toToken(uint256 reward) public pure returns(uint256){
        reward = (reward * 10 ** 18) ;
        return (reward);
    }

    // ---------------------------------------------------------------------------
    function setWaitMinePeriod (uint256 waitingPeriod) public onlyOwner{
        waitMinePeriod = waitingPeriod;
    }
    function setWaitClaimRewardPeriod (uint256 waitingPeriod) public onlyOwner{
        waitClaimRewardPeriod = waitingPeriod;
    }
    function setClaimRewardFee (uint256 newFeeRate) public onlyOwner{
        require(newFeeRate >= 0 && newFeeRate <=100, "Fee rate must be bvetween 0 - 100");
        claimRewardFee = newFeeRate;
    }
    function setRewardPerLevel (uint256 newReward) public onlyOwner{
        rewardPerLevel = newReward;
    }

    function setCaverContract(address newContract) public onlyOwner{
        caver = Caver(newContract);
    }
    function setPickaxeContract(address newContract) public onlyOwner{
        pickaxe = Pickaxe(newContract);
    }
    function setBackpackContract(address newContract) public onlyOwner{
        backpack = Backpack(newContract);
    }
    function setTokenContract(address newContract) public onlyOwner{
        token = Token(newContract);
    }
    function setGetRandom(address newContract) public onlyOwner{
        getRandom = GetRandom(newContract);
    }
    function setGamePoolContract(address newContract) public onlyOwner{
        gamePool = newContract;
    }

    function setPrice(uint choose, uint256 newPrice) public onlyOwner{
        if(choose == 1){ // Caver
            caverPrice = newPrice;
        }if(choose == 2){ // Backpack
            backpackPrice = newPrice;
        }if(choose == 3){ // Pickaxe
            pickaxePrice = newPrice;
        }if(choose == 4){ // Sharpen
            sharpenPrice = newPrice;
        }if(choose == 5){ // Food (divide by 1000)
            foodPrice = newPrice;
        }
    }

    // function _mintPickaxe(uint256 amount) public onlyOwner {
    //     pickaxe.mintPickaxe(msg.sender, amount);
    // }
    
}