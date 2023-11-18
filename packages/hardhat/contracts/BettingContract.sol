// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BettingContract is ERC20 {
    address public owner;
    uint256 betIdCounter;

    struct Bet {
        string description;
        bool isOpen;
        bool outcomeSet;
        mapping(address => uint256) bets;
        uint256 totalBets;
        address[] bettors;
        bool outcome;
    }

    mapping(uint256 => Bet) public bets;

    constructor() ERC20("ConsolationToken", "CT") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function openBet(uint256 _betId, string memory _description) public onlyOwner {
        Bet storage bet = bets[_betId];
        bet.description = _description;
        bet.isOpen = true;
    }

    function bet(uint256 _betId, bool _outcome) public payable {
        Bet storage bet = bets[_betId];
        require(bet.isOpen, "Bet is not open");
        require(!bet.outcomeSet, "Outcome already set");
        bet.bets[msg.sender] += msg.value;
        bet.totalBets += msg.value;
        bet.bettors.push(msg.sender);
    }

    function setOutcome(uint256 _betId, bool _outcome) public onlyOwner {
        Bet storage bet = bets[_betId];
        require(bet.isOpen, "Bet is not open");
        bet.isOpen = false;
        bet.outcome = _outcome;
        bet.outcomeSet = true;
    }

    function withdraw(uint256 _betId) public {
        Bet storage bet = bets[_betId];
        require(bet.outcomeSet, "Outcome not set yet");
        require(bet.bets[msg.sender] > 0, "No bet placed");

        if (bet.outcome) {
            uint256 reward = bet.totalBets * bet.bets[msg.sender] / bet.totalBets;
            payable(msg.sender).transfer(reward);
        } else {
            _mint(msg.sender, 100 * 10**uint(decimals())); // Mint 100 tokens as consolation
        }

        bet.bets[msg.sender] = 0;
    }
}
