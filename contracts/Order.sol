pragma solidity ^0.4.25;

import "./StateMachineLib.sol";
import "./Pricing.sol";

contract Order  {
    using StateMachineLib for StateMachineLib.Data;

    uint public deployedCount = 0;
    uint public onLeaveOrderedCount;
    string public lastTransitionFrom;
    string public lastTransitionTo;
    bool public isDisputed;
    bool public disputeApproved;

    address internal pricingAddress;

    StateMachineLib.Data stateMachine;

    constructor(
        uint[] counts,
        string names,
        address[] addresses,
        string callData,
        bool[] isDelegatecall,
        address _pricingAddress
    ) {
        pricingAddress = _pricingAddress;
        stateMachine.setupStateMachine(counts, names, addresses, callData, isDelegatecall);
    }

    function transition(string transitionName) public {
        stateMachine.transition(transitionName);
    }

    function onLeaveOrdered(uint256 val) public {
        onLeaveOrderedCount += val;
    }

    function canTransition(string from, string to) public {
        require(!(keccak256(from) == keccak256("Ordered") && keccak256(to) == keccak256("Disputed")), "Can't do this transition");
    }
    
    function onTransition(string from, string to) public {
        lastTransitionFrom = from;
        lastTransitionTo = to;
    }

    function toggleDisputed() public {
        isDisputed = !isDisputed;
    }

    function approveDispute(string _transition) public {
        disputeApproved = true;
        transition(_transition);
    }

    function isDisputeApproved() public {
        require(disputeApproved, "Dispute is not approved");
    }

    function onDisputeResolved(string nextState) public {
        if(keccak256(nextState) == keccak256("Deployed")) {
            Pricing(pricingAddress).startOperationalFee();
        }
    }

    function onLeaveDisputed() public {
        Pricing(pricingAddress).stopOperationalFee();
        disputeApproved = false;
    }
}
