// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract RockPaperScissors {
    // Moves
    uint256 public constant ROCK = 1;
    uint256 public constant PAPER = 2;
    uint256 public constant SCISSORS = 3;

    // Player A variables:
    address public playerA;
    bytes32 public playerAEncVote;
    uint256 public playerAVote;
    bool public playerARevealed;

    // Player B variabels:
    address public playerB;
    bytes32 public playerBEncVote;
    uint256 public playerBVote;
    bool public playerBRevealed;

    // general variables:
    uint256 public stake;
    address public winner;
    bool public gameDone;
    uint256 public revealDeadline;

    // Events:
    event revealEvent(address addr, uint256 Vote);
    event playEvent(address addr, bytes32 encVote);
    event withdrawEvent(address addr, uint256 amount);


    function play(uint256 _move, uint256 salt) public payable {
        require(msg.value >= 1 ether, "Bet must be over 1 ether");
        require(_move == 1 || _move == 2 || _move == 3, "Invalid Move");

        if(playerA == address(0)){
            playerA = msg.sender;
            playerAVote = 0;
            playerAEncVote = keccak256(abi.encodePacked(_move, salt));
            playerARevealed = false;
            stake = msg.value;
            emit playEvent(msg.sender, playerAEncVote);
        }
        else if(playerB == address(0)){
            require(msg.sender != playerA, "Same player cannot join the game");
            require(msg.value == stake, "Must match the stake of first player");
            playerB = msg.sender;
            playerBVote = 0;
            playerBEncVote = keccak256(abi.encodePacked(_move, salt));
            playerBRevealed = false;
            emit playEvent(msg.sender, playerBEncVote);
        }
        else {
            revert("Full game");
        }
    }

    function reveal(uint256 _move, uint256 salt) public {
        require(!gameDone, "game is already done");
        require(playerAEncVote != bytes32(0) || playerBEncVote != bytes32(0), "Both players need to vote first");
        if(msg.sender == playerA){
            require(playerARevealed == false, "You have already revealed");
            bytes32 checkVote = keccak256(abi.encodePacked(_move, salt));
            require(checkVote == playerAEncVote, "Invalid reveal"); // assures that player does not change vote when revealing
            playerAVote = _move;
            playerARevealed = true;
            emit revealEvent(msg.sender, _move);
        }
        else if(msg.sender == playerA){
            require(playerBRevealed == false, "You have already revealed");
            bytes32 checkVote = keccak256(abi.encodePacked(_move, salt));
            require(checkVote == playerBEncVote, "Invalid reveal"); 
            playerBVote = _move;
            playerBRevealed = true;
            emit revealEvent(msg.sender, _move);
        }
        else {
            revert("Can not find player");
        }
        if (revealDeadline == 0) {
            revealDeadline = block.timestamp + 60; // 60 seconds to reveal
        }
        if(playerARevealed == true && playerBRevealed == true) {
            winner = findWinner();
            gameDone = true;
            withdraw();
        }
    }

    function findWinner() private view returns (address) {
        if(playerAVote == playerBVote){
            return address(0); // draw
        }
        else if(
            (playerAVote == 1 && playerBVote == 3) || // Rock beats Scissors
            (playerAVote == 2 && playerBVote == 1) || // Paper beats Rock
            (playerAVote == 3 && playerBVote == 2)    // Scissors beats Paper
            )
        {
        return playerA;
        }
        else {
        return playerB;
        }
    }
    function forceWin() public {
        require(revealDeadline > 0, "Reveal phase has not started");
        require(block.timestamp > revealDeadline, "Reveal time has not expired");
        require(!gameDone, "Game is already done");

        // If only player A revealed, they win
        if (playerARevealed && !playerBRevealed) {
            winner = playerA;
        } 
        // If only player B revealed, they win
        else if (playerBRevealed && !playerARevealed) {
            winner = playerB;
        } 

        gameDone = true;
        withdraw();
    }

    function withdraw() private {
        if(winner == address(0)){
            payable(playerA).transfer(stake);
            payable(playerB).transfer(stake);
            emit withdrawEvent(playerA, stake);
            emit withdrawEvent(playerB, stake);
        }
        else{
            payable(winner).transfer(stake*2);
            emit withdrawEvent(winner, stake*2);
        }
        
        resetGame();
    }

    function resetGame() private{
        playerA = address(0);
        playerAEncVote = bytes32(0);
        playerAVote = 0;
        playerARevealed = false;

        playerB = address(0);
        playerBEncVote = bytes32(0);
        playerBVote = 0;
        playerBRevealed = false;

        stake = 0;
        winner = address(0);
        gameDone = false;
        revealDeadline = 0;
    }
}