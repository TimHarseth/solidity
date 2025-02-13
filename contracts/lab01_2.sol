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
    uint256 public revealDeadline = 0;

    // Events:
    event revealEvent(address addr, uint256 Vote);
    event playEvent(address addr, bytes32 encVote);
    event withdrawEvent(address addr, uint256 amount);

    // Play Rock, Paper and Scissors
    function play(bytes32 _hashedVote) public payable {
        require(msg.value >= 1 ether, "Bet must be over 1 ether");
        if(playerA == address(0)){
            playerA = msg.sender;
            playerAVote = 0;
            playerAEncVote = _hashedVote;
            playerARevealed = false;
            stake = msg.value;
            emit playEvent(msg.sender, playerAEncVote);
        }
        else if(playerB == address(0)){
            require(msg.sender != playerA, "Same player cannot join the game");
            require(msg.value == stake, "Must match the stake of first player");
            playerB = msg.sender;
            playerBVote = 0;
            playerBEncVote = _hashedVote;
            playerBRevealed = false;
            emit playEvent(msg.sender, playerBEncVote);
        }
        else {
            revert("Full game");
        }
    }

    function reveal(uint256 _move, uint256 salt) public {
        require(!gameDone, "game is already done");
        require(playerAEncVote != bytes32(0) && playerBEncVote != bytes32(0), "Both players need to vote first");
        if(msg.sender == playerA){
            require(playerARevealed == false, "You have already revealed");
            bytes32 checkVote = keccak256(abi.encodePacked(_move, salt));
            require(checkVote == playerAEncVote, "Invalid reveal"); // assures that hashedVote and reveal parameters are valid
            playerAVote = _move;
            playerARevealed = true;
            emit revealEvent(msg.sender, _move);
        }
        else if(msg.sender == playerB){
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
            revealDeadline = block.timestamp + 3 minutes; // 3 minutes to reveal
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

    function withdraw() public {
        require(gameDone == true);
        require(msg.sender == playerA || msg.sender == playerB, "Not a player in this game");
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
    }

    function resetGame() public{
        require(gameDone == true);
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

/*TESTING HASH

0xd8dec90d0976f60ca43a5479e6fe32e37efc8928dc1f66fec4099a94f16c4347 | 1,444

0xf806280aa4dfe145596c627f696302876be30d4ea721e7e2b62aecde7954710a | 1,255

0xc738b5b09a9697438b038e38384f7abd49615ca1942159a1844b9d47bd06540f | 2,777

*/