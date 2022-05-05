// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GetRandom { // random from 0 to 999
    function random(uint256 input) public view returns(uint256){
        uint256 randomNumber;
        randomNumber = uint256( keccak256( abi.encodePacked(block.timestamp, msg.sender, input) ) ) % 1000;

        return randomNumber;
    }
}