// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IChronicleOracle {
    function requestOutcome(uint256 _betId) external returns (bytes32 requestId);
    function getOutcome(bytes32 _requestId) external view returns (bool outcome, bool isAvailable);
}

contract BettingContract is ERC20, AccessControl {
    bytes32 public constant BET_CREATOR_ROLE = keccak256("BET_CREATOR_ROLE");
    address public owner;
    uint256 public betIdCounter;
    IChronicleOracle public oracle;

    struct Bet {
        string description;
        bool isOpen;
        bool outcomeSet;
        mapping(address => uint256) bets;
        uint256 totalBets;
        address[] bettors;
        bool outcome;
        bool isPrivate;
        bytes32 oracleRequestId;
    }

    mapping(uint256 => Bet) public bets;
    mapping(uint256 => mapping(address => bool)) private invitedBettors;

    constructor() ERC20("ConsolationToken", "CT") {
        owner = msg.sender;
        oracle = IChronicleOracle(_oracleAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // Sets the deployer as the default admin
    }

    modifier onlyBetCreator(uint256 _betId) {
        require(hasRole(BET_CREATOR_ROLE, msg.sender) || bets[_betId].creator == msg.sender, "Not authorized");
        _;
    }

    function openBet(uint256 _betId, string memory _description, bool _isPrivate) public {
        require(hasRole(BET_CREATOR_ROLE, msg.sender), "Caller is not a bet creator");
        betIdCounter++;
        Bet storage bet = bets[_betId];
        bet.description = _description;
        bet.isOpen = true;
        bet.creator = msg.sender;
        bet.isPrivate = _isPrivate;
    }

    function inviteToBet(uint256 _betId, address _bettor) public onlyBetCreator(_betId) {
        invitedBettors[_betId][_bettor] = true;
    }

    function bet(uint256 _betId, bool _outcome) public payable {
        Bet storage bet = bets[_betId];
        require(bet.isOpen, "Bet is not open");
        require(!bet.outcomeSet, "Outcome already set");
        require(!bet.isPrivate || invitedBettors[_betId][msg.sender], "Not invited to this bet");

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

    function requestOutcomeFromOracle(uint256 _betId) public onlyOwner {
        Bet storage bet = bets[_betId];
        require(bet.isOpen, "Bet is not open");
        bet.oracleRequestId = oracle.requestOutcome(_betId);
    }

    function setOutcomeFromOracle(uint256 _betId) public {
        Bet storage bet = bets[_betId];
        (bool outcome, bool isAvailable) = oracle.getOutcome(bet.oracleRequestId);
        require(isAvailable, "Outcome not available yet");

        bet.isOpen = false;
        bet.outcome = outcome;
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

    function grantBetCreatorRole(address _account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        grantRole(BET_CREATOR_ROLE, _account);
    }

    function revokeBetCreatorRole(address _account) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        revokeRole(BET_CREATOR_ROLE, _account);
    }
}
