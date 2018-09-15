pragma solidity ^0.4.24;

import "./DefinableStateMachine.sol";

contract StateMachine is DefinableStateMachine {

    function transition(string _name) public returns (bool) {
        uint256 transitionIndex;
        bool exists;
        (transitionIndex, exists) = findTransitionIndex(stateId, _name);
        require(exists, "Transition doesn't exist");
        
        return executeAutoTransition() || executeTransition(states[stateId].transitions[transitionIndex]);
    }

    function executeAutoTransition() internal returns (bool) {
        Transition[] storage transitions = states[stateId].transitions;

        for(uint256 i = 0; i < transitions.length; i++) {
            if(transitions[i].auto && executeTransition(transitions[i])) 
                return true;
        }
        
        return false;
    }

    function executeTransition(Transition _transition) internal returns (bool) {
        if(executeCall(_transition.condition)) {
            executeCall(_transition.trigger);
            stateId = _transition.nextStateId;

            executeAutoTransition();
            return true;
        }
    }

    function executeCall(Func _call) internal returns (bool) {
        return _call.contractAddress.delegatecall(_call.signature);
    }
}