pragma solidity ^0.4.24;

import "./DefinableStateMachine.sol";

/**
 * @title StateMachine
 * @dev Contract implements state machine logic
 */
contract StateMachine is DefinableStateMachine {

    event TransitionExecuted(
        uint256 indexed fromState, 
        uint256 indexed toState,
        string name
    );

    /**
    * @dev Perform state transition
    * @notice While performing transition, we first check if the current state
    * has auto transitions. They are iterated over and the first one whose condition
    * call returns true is executed. In the next state auto transitions are again 
    * executed recursively.
    * @return true if transition was successful
    */
    function transition(string _name) 
        public 
        returns (bool) 
    {
        require(
            bytes(states[stateId].transitions[_name].name).length > 0, 
            "Transition doesn't exist"
        );
        
        return executeAutoTransition() 
            || executeTransition(states[stateId].transitions[_name]);
    }

    ///@dev Look for auto transitions in current state and try to execute them
    ///@return true if auto transition was executed
    function executeAutoTransition() 
        internal 
        returns (bool) 
    {
        string[] storage autoTransitions = states[stateId].autoTransitions;

        for(uint256 i = 0; i < autoTransitions.length; i++) {
            if(executeTransition(states[stateId].transitions[autoTransitions[i]]))
                return true;
        }
        
        return false;
    }

    /**
    * @dev Execute a transition
    * @notice If condition is defined for the transition it is first called 
    * to determine if transition is allowed. Then action trigger is executed,
    * the state is changed and finally auto transitions on the new state are executed.
    * @return true if transition was successful
    */
    function executeTransition(Transition _transition) 
        internal 
        returns (bool) 
    {
        if(
            _transition.condition.contractAddress == address(0) 
            || executeCall(_transition.condition)
        ) {
            if(_transition.trigger.contractAddress != address(0)) 
                executeCall(_transition.trigger);

            emit TransitionExecuted(stateId, _transition.nextStateId, _transition.name);

            stateId = _transition.nextStateId;

            executeAutoTransition();
            return true;
        }
        
        return false;
    }

    ///@dev Execute delegatecall to given contract with given signature
    ///@return true if the call did not revert 
    function executeCall(Func _call) 
        internal 
        returns (bool) 
    {
        return _call.contractAddress.delegatecall(_call.signature);
    }
}