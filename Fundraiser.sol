// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Fundraiser {
    
    
    mapping(address => uint) public contributions;
    address[] public contributorsList;
    
    uint public constant MIN_AMOUNT = 1000000;
    
    address public owner;
    string  public title;
    string  public description;
    uint256 public goal;
    uint256 public deadline;
    uint256 public totalAmount; 
    bool    public ownerHasWithdrawn; 

    
    event Donated(address indexed donor, uint amount, uint newTotal);
    event FundsWithdrawn(address indexed owner, uint amount);
    event Refunded(address indexed donor, uint amount);

    
    constructor(string memory _title, string memory _description, uint _goal, uint _durationSeconds) {
        owner = msg.sender;
        title = _title;
        description = _description;
        goal = _goal;
        deadline = block.timestamp + _durationSeconds;
    }

    
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the Owner!!");
        _;
    }

    
    function donate() external payable {
        require(block.timestamp <= deadline, "Time is up!! SORRY");
        require(totalAmount < goal, "Goal has been reached!!");
        require(msg.value >= MIN_AMOUNT, "Amount Selected is very low");
        
        
        if (contributions[msg.sender] == 0) {
            contributorsList.push(msg.sender);
        }

        contributions[msg.sender] += msg.value;
        totalAmount += msg.value;

        emit Donated(msg.sender, msg.value, totalAmount);
    }

    function withdraw() external onlyOwner { 
        require(block.timestamp >= deadline || totalAmount >= goal, "Campaign active");
        require(totalAmount >= goal, "We have not reached the GOAL");
        require(!ownerHasWithdrawn, "Already Withdrawn");
        
       
        ownerHasWithdrawn = true;
        uint256 amountToWithdraw = address(this).balance; 
        
        
        (bool success, ) = payable(owner).call{value: amountToWithdraw}("");
        require(success, "Owner withdrawal failed");

        emit FundsWithdrawn(owner, amountToWithdraw);
    }

    function refund() public {
        require(block.timestamp >= deadline, "Campaign still active");
        require(totalAmount < goal, "Goal was reached, no refunds");
        
        uint amountToRefund = contributions[msg.sender];
        require(amountToRefund > 0, "No amount to refund");

        
        contributions[msg.sender] = 0; 

        
        (bool success, ) = payable(msg.sender).call{value: amountToRefund}("");
        require(success, "Refund transfer failed");
        
        emit Refunded(msg.sender, amountToRefund);
    }
    
    function getStatus() external view returns (
            bool isActive,
            bool goalReached,
            uint256 remaining,
            uint256 timeLeft
        )
    {
        isActive    = block.timestamp < deadline;
        goalReached = totalAmount >= goal;
        remaining   = totalAmount >= goal ? 0 : goal - totalAmount;
        timeLeft    = block.timestamp < deadline ? deadline - block.timestamp : 0;
    }
}
