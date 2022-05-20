// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./Token.sol";

contract TestTokenPay is Token {

    Token public token = Token(0x5e6C055331122A6EA75b39cC0b5F4D6E36F9866f);
    
    address public gamePool = 0xb8DE0C06A0d55584e7DA4148F352Ed9fF4595367;


    function ReceiveToken(
        uint256 amount
    ) public {
        // player must give allowance to Gameplay contract first;
        // uint256 allowance = token.allowance(msg.sender, address(this));
        // require(allowance >= amount, "Player : Insufficient allowance");
        // require(token.balanceOf(msg.sender) >= amount, "Player : Insufficient balance");

        transferFrom(msg.sender, gamePool, amount);
    }

    function transferFrom( //ถ้าเรียก function นี้โดยตรง จะสามารถแสดงจำนวน Token ได้
        address from,
        address to,
        uint256 amount,
        uint256 choose
    ) public returns (bool) {
        
        // uint256 allowance = token.allowance(msg.sender, address(this));
        // require(allowance >= amount, "Player : Insufficient allowance");
        // require(token.balanceOf(msg.sender) >= amount, "Player : Insufficient balance");

        token.transferFrom(from, to, amount);

        return true;
    }

}