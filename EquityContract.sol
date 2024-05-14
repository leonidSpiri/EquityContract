// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EquityContract {
    address payable public owner;
    address[] investors;
    mapping(address => uint256) public investorSharePercentage;
    mapping(address => uint256) public investorShareValue;
    mapping(address => bool) public investorIntentToSell;
    uint256 public projectCost; 
    uint256 public remainingSharesPercentage;
    uint256 public etherToEuroRate;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier requiresEther() {
        require(msg.value > 0, "Ether transfer expected");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
        remainingSharesPercentage = 100;
        projectCost = 100000000000000000000;
        etherToEuroRate = 2000000000000000000000;
    }

    function contribute(address contributor) external payable requiresEther {
        require(msg.sender != owner, "Owner cannot contribute");

        if (contributor == owner) {
            uint256 contributionPercentage = (msg.value * 100) / projectCost;
            require(contributionPercentage <= remainingSharesPercentage,"Contribution exceeds remaining shares percentage");

            investorSharePercentage[msg.sender] += contributionPercentage;
            remainingSharesPercentage -= contributionPercentage;
            investorShareValue[msg.sender] += msg.value;
            investors.push(msg.sender);
        }
 
        else if (investorIntentToSell[contributor]) {
            require(msg.value == investorShareValue[contributor], "Contribution value does not match investor's share");
            investorSharePercentage[msg.sender] += investorSharePercentage[contributor];
            investorSharePercentage[contributor] = 0;
            investorShareValue[msg.sender] += investorShareValue[contributor];
            investorShareValue[contributor] = 0;
            investorIntentToSell[contributor] = false;
            for (uint i = 0; i < investors.length; i++) {
                if (investors[i] == contributor) {
                    if (investorSharePercentage[msg.sender] > 0) {
                        investors[i] = msg.sender;
                    }
                    else {
                        for (uint j = i; j < investors.length - 1; i++) {
                            investors[i] = investors[i + 1];
                        }
                        investors.pop();
                    }
                    break;
                }
            }
            }

        else {
            revert ("The contributor has not identified the intention and is not the owner");
        }

        payable(contributor).transfer(msg.value);
    }

    function setIntentToSell(bool _intent) external {
        require(msg.sender != owner, "Owner cannot set intent to sell");
        require(investorSharePercentage[msg.sender] != 0, "You have not purchased a share");
        investorIntentToSell[msg.sender] = _intent;
    }

    function ownerUpdateCost(uint _newPrice) external onlyOwner {
        projectCost = _newPrice;
            for (uint256 i = 0; i < investors.length; i++) {
                investorShareValue[investors[i]] = (_newPrice / 100) * investorSharePercentage[investors[i]];
        }

    }

    function setEtherToEuroRate(uint256 _rate) external {
        etherToEuroRate = _rate;
    }

    function projectCostInEuro() external view returns (uint256) {
        require(etherToEuroRate > 0, "Ether to Euro rate not set");
        uint256 weiToEth = projectCost / (10**18);
        uint256 ethToEuro = weiToEth * etherToEuroRate;
        return ethToEuro;
    }
}
