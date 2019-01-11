pragma solidity ^0.4.25;

import "./StateMachineLib.sol";

contract Order  {
    using StateMachineLib for StateMachineLib.Data;

    uint public deployedCount = 0;
    uint public transitionVal;

    StateMachineLib.Data stateMachine;

    event TestBytes(bytes Bytes);
    event TestBytes1(bytes1 Bytes);
    event TestUint(uint256 Uint);

    constructor(
        uint[] counts,
        string names,
        address[] addresses,
        string callData,
        bool[] isDelegatecall
    ) {
        stateMachine.setupStateMachine(counts, names, addresses, callData, isDelegatecall);
    }

    function transition(string transitionName) public {
        stateMachine.transition(transitionName);
    }

    function onDeployed() public {
        deployedCount++;
    }

    function onTransition(uint val) public {
        transitionVal = val;
    }
    
}
