pragma solidity ^0.4.25;

import "./StateMachineLib.sol";
import "./Pricing.sol";

contract Order  {
    using StateMachineLib for StateMachineLib.Data;

    uint public deployedCount = 0;
    uint public onLeaveOrderedVal;
    string public lastTransitionFrom;
    string public lastTransitionTo;
    bool public isDisputed;
    bool public disputeApproved;

    address internal pricingAddress;

    StateMachineLib.Data stateMachine;


    event TestBytes(bytes Bytes);
    event TestBytes1(bytes1 Bytes);
    event TestUint(uint256 Uint);
    event TestBool(bool Bool);
    event TestOrdered();

    constructor(
        uint[] counts,
        string names,
        address[] addresses,
        string callData,
        bool[] isDelegatecall,
        address _pricingAddress
    ) 
        public
    {
        pricingAddress = _pricingAddress;
        stateMachine.setupStateMachine(counts, names, addresses, callData, isDelegatecall);
    }

    function transition(string transitionName) public {
        stateMachine.transition(transitionName);
    }

    function getCurrentState() public view returns (string) {
        return stateMachine.state;
    }

    function onLeaveOrdered(uint256 val) public {
        onLeaveOrderedVal = val;
    }

    function canTransition(string from, string to) public pure {
        require(!(keccak256(abi.encodePacked(from)) == keccak256(abi.encodePacked("Ordered")) 
            && keccak256(abi.encodePacked(to)) == keccak256(abi.encodePacked("Disputed"))), "Can't do this transition");
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

    function isDisputeApproved() public view {
        require(disputeApproved, "Dispute is not approved");
    }

    function onDisputeResolved(string nextState) public {
        if(keccak256(abi.encodePacked(nextState)) == keccak256(abi.encodePacked("Deployed"))) {
            Pricing(pricingAddress).startOperationalFee();
        }
    }

    function onLeaveDeployed() public {
        Pricing(pricingAddress).stopOperationalFee();
    }
}
