// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract RockPaperScissors {
    address payable public player1;
    address payable public player2;
    uint256 public minimumBet = 0.0001 ether;
    uint256 public contractBalance;

    enum Move { None, Rock, Paper, Scissors }

    struct Game {
        address player;
        bytes32 hashedMove;
        Move move;
        string clearMove;
        bool revealed;
    }

    mapping(address => Game) public games;
    bool public gameFinished;

    modifier onlyRegisteredPlayers() {
        require(msg.sender == player1 || msg.sender == player2, "You are not registered as a player.");
        _;
    }

    modifier gameNotFinished() {
        require(!gameFinished, "The game is already finished.");
        _;
    }

    constructor() {
        player1 = payable(address(0));
        player2 = payable(address(0));
    }

    function register() external payable gameNotFinished {
        require(msg.value >= minimumBet, "Insufficient bet amount.");
        if (player1 == address(0)) {
            player1 = payable(msg.sender);
        } else if (player2 == address(0)) {
            player2 = payable(msg.sender);
        } else {
            revert("Both players are already registered.");
        }
    }

    function play(bytes32 encrMove) external onlyRegisteredPlayers gameNotFinished {
        require(games[msg.sender].hashedMove == bytes32(0), "You've already played.");
        games[msg.sender].hashedMove = encrMove;
    }

    function reveal(string memory clearMove) external onlyRegisteredPlayers gameNotFinished {
        require(keccak256(abi.encodePacked(clearMove)) == games[msg.sender].hashedMove, "Invalid clear move.");
        require(games[msg.sender].revealed == false, "You've already revealed your move.");
        games[msg.sender].clearMove = clearMove;
        games[msg.sender].move = getMoveFromString(clearMove);
        games[msg.sender].revealed = true;

        if (games[player1].revealed && games[player2].revealed) {
            determineWinner();
        }
    }

    function determineWinner() internal {
        require(games[player1].revealed && games[player2].revealed, "Both players must reveal their moves.");
        require(!gameFinished, "The game is already finished.");

        Move move1 = games[player1].move;
        Move move2 = games[player2].move;

        if (move1 == move2) {
            player1.transfer(minimumBet);
            player2.transfer(minimumBet);
        } else if (
            (move1 == Move.Rock && move2 == Move.Scissors) ||
            (move1 == Move.Paper && move2 == Move.Rock) ||
            (move1 == Move.Scissors && move2 == Move.Paper)
        ) {
            player1.transfer(contractBalance);
        } else {
            player2.transfer(contractBalance);
        }

        gameFinished = true;
    }

    function getMoveFromString(string memory moveStr) internal pure returns (Move) {
        if (keccak256(abi.encodePacked(moveStr)) == keccak256(abi.encodePacked("Rock"))) {
            return Move.Rock;
        } else if (keccak256(abi.encodePacked(moveStr)) == keccak256(abi.encodePacked("Paper"))) {
            return Move.Paper;
        } else if (keccak256(abi.encodePacked(moveStr)) == keccak256(abi.encodePacked("Scissors"))) {
            return Move.Scissors;
        } else {
            return Move.None;
        }
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function whoAmI() external view returns (uint256) {
        if (msg.sender == player1) {
            return 1;
        } else if (msg.sender == player2) {
            return 2;
        } else {
            return 0;
        }
    }

    function bothPlayed() external view returns (bool) {
        return games[player1].hashedMove != bytes32(0) && games[player2].hashedMove != bytes32(0);
    }

    function bothRevealed() external view returns (bool) {
        return games[player1].revealed && games[player2].revealed;
    }

    function revealTimeLeft() external view returns (uint256) {
        if (!games[player1].revealed || !games[player2].revealed) {
            return 0; // Disclosure phase hasn't started yet
        } else {
            // Add your logic to calculate the remaining time if needed
            return 0;
        }
    }
}
