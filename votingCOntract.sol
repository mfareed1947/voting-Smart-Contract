// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract vote {
    struct Voter {
        string voterName;
        uint256 voterId;
        uint256 age;
        Gender gender;
        address voterAddress;
        uint256 voteCandiateId;
    }
    struct Candiate {
        string candiateName;
        Gender candiateGender;
        string party;
        uint256 age;
        uint256 candiateId;
        address candiateAdress;
        uint256 votes;
    }
    address public winner;

    address public electionCommisson;

    uint256 nextVoterId = 1;
    uint256 nextCandiateId = 1;

    uint256 startTime;
    uint256 endTime;
    bool stopVoting;

    mapping(uint256 => Voter) voterDetails;
    mapping(uint256 => Candiate) candiateDetails;

    enum VotingStatus {
        NotStarted,
        InProgress,
        Ended
    }
    enum Gender {
        Male,
        Female,
        Other
    }

    constructor() {
        electionCommisson = msg.sender;
    }

    modifier isVoteOver() {
        require(
            block.timestamp <= endTime || stopVoting == false,
            "vote Time is over"
        );
        _;
    }
    modifier onlyCommissioner() {
        require(electionCommisson == msg.sender, "Not Authorized");
        _;
    }
    modifier ageCheck(uint256 _age) {
        require(_age >= 18, "You are below 18");
        _;
    }

    function registerCandiate(
        string calldata _name,
        string calldata _party,
        uint256 _age,
        Gender _gender
    ) external ageCheck(_age) {
        require(isCandiateNotRegister(msg.sender), "You are alredy registered");
        require(nextCandiateId < 3, "Candiate Registration Full");
        require(
            msg.sender != electionCommisson,
            "ElectionCommission is not Allowed"
        );
        candiateDetails[nextCandiateId] = Candiate(
            _name,
            _gender,
            _party,
            _age,
            nextCandiateId,
            msg.sender,
            0
        );
        nextCandiateId++;
    }

    function registerVoter(
        string calldata _name,
        uint256 _age,
        Gender _gender
    ) external ageCheck(_age) {
        require(isVoterNotRegister(msg.sender), "You are alredy registered");
        voterDetails[nextVoterId] = Voter(
            _name,
            _age,
            nextVoterId,
            _gender,
            msg.sender,
            0
        );
        nextVoterId++;
    }

    function isCandiateNotRegister(address _person)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 1; i < nextCandiateId; i++) {
            if (candiateDetails[i].candiateAdress == _person) {
                return false;
            }
        }
        return true;
    }

    function isVoterNotRegister(address _person) internal view returns (bool) {
        for (uint256 i = 1; i < nextVoterId; i++) {
            if (voterDetails[i].voterAddress == _person) {
                return false;
            }
        }
        return true;
    }

    function getCandiateList() public view returns (Candiate[] memory) {
        Candiate[] memory candiateList = new Candiate[](nextCandiateId - 1);

        for (uint256 i = 0; i < candiateList.length; i++) {
            candiateList[i] = candiateDetails[i + 1];
        }
        return candiateList;
    }

    function getVoterList() public view returns (Voter[] memory) {
        Voter[] memory VoterList = new Voter[](nextVoterId - 1);

        for (uint256 i = 0; i < VoterList.length; i++) {
            VoterList[i] = voterDetails[i + 1];
        }
        return VoterList;
    }

    function castVote(uint256 _voterId, uint256 _candiateId)
        external
        isVoteOver
    {
        require(block.timestamp >= startTime, "Voting has not started");
        require(
            voterDetails[_voterId].voteCandiateId == 0,
            "You are alredy voted"
        );
        require(
            voterDetails[_voterId].voterAddress == msg.sender,
            "You are not authorized"
        );
        require(_candiateId >= 1 && _candiateId < 3, "You are alredy voted");
        voterDetails[_voterId].voteCandiateId = _candiateId;
        candiateDetails[_candiateId].votes++;
    }

    function setVotingPeriod(
        uint256 _startTimeDuration,
        uint256 _endTimeDuration
    ) external onlyCommissioner {
        require(
            _endTimeDuration > 3600,
            "_endTimeDuration must be greater than 1 hour"
        );
        startTime = block.timestamp + _startTimeDuration;
        endTime = block.timestamp + _endTimeDuration;
    }

    function getVotingStatus() public view returns (VotingStatus) {
        if (startTime == 0) {
            return VotingStatus.NotStarted;
        } else if (endTime > block.timestamp && stopVoting == false) {
            return VotingStatus.InProgress;
        } else {
            return VotingStatus.Ended;
        }
    }

    function announceVotingResult() external onlyCommissioner {
        uint256 maxVote = 0;
        for (uint256 i = 1; i <= nextCandiateId; i++) {
            if (candiateDetails[i].votes > maxVote) {
                maxVote = candiateDetails[i].votes;
                winner = candiateDetails[i].candiateAdress;
            }
        }
    }

    function emergencyStopVoting() public onlyCommissioner {
        stopVoting = true;
    }
}
