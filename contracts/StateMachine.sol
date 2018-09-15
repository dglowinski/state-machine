pragma solidity ^0.4.24;

import "./DefinableStateMachine.sol";

//TODO
// comments
// format
// solium
// events
// change condition signature to data
// add data to transition trigger
// warnings
// update solidity
// update truffle

contract StateMachine is DefinableStateMachine {

    function transition(string _name) public returns (bool) {
        require(bytes(states[stateId].transitions[_name].name).length > 0, "Transition doesn't exist");
        
        return executeAutoTransition() || executeTransition(states[stateId].transitions[_name]);
    }

    function executeAutoTransition() internal returns (bool) {
        string[] storage autoTransitions = states[stateId].autoTransitions;

        for(uint256 i = 0; i < autoTransitions.length; i++) {
            if(executeTransition(states[stateId].transitions[autoTransitions[i]]))
                return true;
        }
        
        return false;
    }

    function executeTransition(Transition _transition) internal returns (bool) {
        if(_transition.condition.contractAddress == address(0) || executeCall(_transition.condition)) {
            if(_transition.trigger.contractAddress != address(0)) 
                executeCall(_transition.trigger);

            stateId = _transition.nextStateId;

            executeAutoTransition();
            return true;
        }
        
        return false;
    }

    function executeCall(Func _call) internal returns (bool) {
        return _call.contractAddress.delegatecall(_call.signature);
    }
}