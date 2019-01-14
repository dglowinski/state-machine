pragma solidity ^0.4.25;

contract Pricing {
    uint public installationsCount;
    uint public operationalCount;

    function chargeFees() public {
        installationsCount++;
        operationalCount++;
    }

    function stopOperationalFee() public {
        operationalCount--;
    }

    function startOperationalFee() public {
        operationalCount++;
    }
}