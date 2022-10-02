// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC20.sol";

contract CrowdFund {

    event Launch (
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );

    event Cancel(uint id);

    event Pledge(uint indexed id, address indexed caller ,uint _amount);

    event Unpledge(uint indexed id, address indexed caller ,uint _amount);

    event Claim(uint id);   

    event Refund(uint indexed id, address indexed caller, uint balance);

    struct Campaign {
        address creator;
        uint pledged;
        uint goal;
        uint32 startAt;
        uint32 endAt;
        bool claimed;   
    }

    IERC20 public immutable token;
    uint public count = 0;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    } 


    function launch(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt
    ) external {
        require(_startAt >= block.timestamp, "ERROR : start at < now");
        require(_endAt >= _startAt, "ERROR : end at < start at");
        require(_endAt >= block.timestamp + 90 days, "ERROR: end at greater than max duration");

        campaigns[count] = Campaign({
            creator: msg.sender,
            pledged: 0,
            goal: _goal,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false 
        });    

        emit Launch(count, msg.sender, _goal, _startAt, _endAt);  

        count += 1;
    } 


    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "ERROR : The sender is not a creator!");
        require(block.timestamp < campaign.startAt, "ERROR : started");
        delete campaigns[_id];

        emit Cancel(_id);
    }


    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "ERROR: The Campaign is not started!");
        require(block.timestamp <= campaign.endAt, "ERROR: The Campaign is ended");

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;   
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }


    function unpledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp <= campaign.endAt, "ERROR: The Campaign is ended!");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }


    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "ERROR: The message sender is not a creator!");
        require(block.timestamp > campaign.endAt, "ERROR: The Campaign is not end yet!");
        require(campaign.pledged >= campaign.goal, "ERROR: pledged < goal");
        require(!campaign.claimed, "ERROR: Amount of the pledge was claimed!");

        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);

        emit Claim(_id);
    }

    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "ERROR: The Campaign is not end yet!");
        require(campaign.pledged < campaign.goal, "ERROR: pledged > goal");

        uint balance = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, balance);

        emit Refund(_id, msg.sender, balance);

    }
}

