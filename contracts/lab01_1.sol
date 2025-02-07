// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
// it costs 280019 gas to call the helloFunc Function
contract myContract {
    event hello(string message);

    function helloFunc (string memory _msg) public{
        emit hello(_msg);
    }
}