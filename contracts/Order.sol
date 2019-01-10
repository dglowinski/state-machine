pragma solidity ^0.4.25;

import "./StateMachineLib.sol";

contract Order  {
    using StateMachineLib for StateMachineLib.Data;

    uint public deployedCount = 0;
    uint public transitionVal;

    StateMachineLib.Data stateMachine;

    constructor(
        uint[] counts,
        string names,
        address[] addresses,
        string callData,
        bool[] isDelegatecall
    ) {
        stateMachine.setupStatesAndTransitions(counts, names, addresses, callData, isDelegatecall);
    }

    function onDeployed() public {
        deployedCount++;
    }

    function onTransaction(uint val) {
        transitionVal = val;
    }
    
}
