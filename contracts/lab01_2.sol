// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract RockPaperScissor {
    uint public firstBet = 0;
    
    enum Moves {None, Rock, Paper, Scissor} // All possible moves
    enum Won {PlayerA, PlayerB, Draw} // All outcomes

    struct Game {
        address playerA;
        address playerB;
        bytes32 encMoveA;
        bytes32 encMoveB;
        uint stake;
    }

    mapping(uint256 => Game) public games;
    uint public gameID = 0;

    function play(bytes32 hashedMove) public payable {
        if (games[gameID].playerA == address(0)){ // first player
            games[gameID] = Game({
                playerA: msg.sender,
                playerB: address(0),
                encMoveA: hashedMove,
                encMoveB: 0,
                stake: msg.value
            });
        }
        else { // second player
            games[gameID] = Game({
                Game storage game = games[gameIdCounter];

                require(game.playerB == address(0), "Game is full");
                require(msg.value == game.stake, "Stake must match");
            })
        }
    }
}