pragma solidity ^0.4.24;

import "./StateMachineStorage.sol";

/**
 * @title DefinableStateMachine
 * @dev Contract implements functions to create and modify states and transitions
 */
contract DefinableStateMachine is StateMachineStorage {

    modifier onlyIfStateExists(uint256 _stateId) {
        require(states[_stateId].id != 0, "State doesn't exist");
        _;
    }
    
    event AddState(uint256 id, string name);
    event DeleteState(uint256 id);
    event AddTransition(uint256 indexed stateId, string name);
    event DeleteTransition(uint256 indexed stateId, string name);

    ///@dev Create a new state if not already exists
    function addState(uint256 _id, string _name) 
        external 
        onlyOwner 
    {
        require(_id != 0, "Id 0 not allowed");
        require(states[_id].id == 0, "State already exists");
        
        states[_id] = State(_id, _name, new string[](0));
        if(stateId == 0) stateId = _id;

        emit AddState(_id, _name);
    }

    ///@dev Delete a state by id, unless it's current state
    function deleteState(uint256 _id) 
        external 
        onlyOwner 
    {
        require(stateId != _id, "Can't delete current state");
        delete states[_id];

        emit DeleteState(_id);
    }

    /**
    * @dev Define new transition for the state
    * @notice Transitions are invoked by name. First a condition call is executed and if
    * it returns true, a trigger call is executed and state is changed. Auto transitions
    * have precedence over regular transitions
    */
    function addTransition(
        uint256 _stateId, 
        string _name,
        address _conditionContract,
        bytes32 _conditionSignature,
        address _triggerContract,
        bytes32 _triggerSignature,
        uint256 _nextStateId,
        bool _auto
    ) 
        external 
        onlyOwner 
        onlyIfStateExists(_stateId) 
    {
        require(bytes(_name).length > 0, "Transition name required");
        require(
            bytes(states[_stateId].transitions[_name].name).length == 0, 
            "Transition already exists"
        );
        
        states[_stateId].transitions[_name] = Transition({
            name: _name,
            condition: Func(_conditionContract, _conditionSignature),
            trigger: Func(_triggerContract, _triggerSignature),
            auto: _auto,
            nextStateId: _nextStateId
        });

        if(_auto) states[_stateId].autoTransitions.push(_name);

        emit AddTransition(_stateId, _name);
    }

    ///@dev Delete transition by state id and name
    function deleteTransition(uint256 _stateId, string _name) 
        external 
        onlyOwner 
    {
        State storage state = states[_stateId];

        if(state.transitions[_name].auto) {
            uint256 autoIndex;
            for(uint256 i = 0; i < state.autoTransitions.length; i++) {
                if(keccak256(bytes(state.autoTransitions[i])) == keccak256(bytes(_name))) 
                    autoIndex = i;
            }

            state.autoTransitions[autoIndex] = state.autoTransitions[state.autoTransitions.length - 1];
            state.autoTransitions.length -= 1;
        }
        delete state.transitions[_name];

        emit DeleteTransition(_stateId, _name);
    }

    ///@dev Get current state name
    ///@return Current state name
    function getCurrentStateName() 
        external 
        view 
        returns(string) 
    {
        return states[stateId].name;
    }
}