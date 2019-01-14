pragma solidity ^0.4.25;

contract Pricing {
    uint public installationsCount;
    uint public operationalCount;

    event PricingTest(uint val);
    event Charge(uint val);

    function chargeFees() public {
        
        installationsCount++;
        operationalCount++;

        emit Charge(operationalCount);
    }

    function stopOperationalFee() public {
        emit PricingTest(operationalCount);
        operationalCount--;

        emit PricingTest(operationalCount);
    }

    function startOperationalFee() public {
        operationalCount++;
    }
}