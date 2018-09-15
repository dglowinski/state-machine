pragma solidity ^0.4.24;

import "./StateMachineStorage.sol";

contract DefinableStateMachine is StateMachineStorage {

    uint256 internal constant maxTransitions = 100;

    modifier onlyIfStateExists(uint256 _stateId) {
        require(states[_stateId].id != 0, "State doesn't exist");
        _;
    }

    function addState(uint256 _id, string _name) external onlyOwner {
        require(_id != 0, "Id 0 not allowed");
        require(states[_id].id == 0, "State already exists");
        states[_id] = State(_id, _name, new Transition[](0));
    }

    function deleteState(uint256 _id) external onlyOwner {
        delete states[_id];
    }

    function addTransition(
        uint256 _stateId, 
        string _name,
        address _conditionContract,
        bytes32 _conditionSignature,
        address _triggerContract,
        bytes32 _triggerSignature,
        uint256 _nextStateId,
        bool _auto
    ) external onlyOwner onlyIfStateExists(_stateId) {
        require(_conditionContract != address(0), "Condition contract required");
        require(_triggerContract != address(0), "Trigger contract required");
        require(states[_stateId].transitions.length < maxTransitions, "Max number of transitions");

        bool exists;
        (, exists) = findTransitionIndex(_stateId, _name);
        require(!exists, "Transition already exists");
        
        states[_stateId].transitions.push(Transition({
            name: _name,
            condition: Func(_conditionContract, _conditionSignature),
            trigger: Func(_triggerContract, _triggerSignature),
            auto: _auto,
            nextStateId: _nextStateId
        }));
    }

    function deleteTransition(uint256 _stateId, string _name) 
        external 
        onlyOwner
        onlyIfStateExists(_stateId) 
    {
        uint transitionIndex;
        bool exists;
        (transitionIndex, exists) = findTransitionIndex(_stateId, _name);
        require(exists, "Transition doesn't exist");

        Transition[] storage transitions = states[_stateId].transitions;
        transitions[transitionIndex] = transitions[transitions.length - 1];
        transitions.length -= 1;        
    }

    function findTransitionIndex(uint256 _stateId, string _name) 
        internal 
        view
        onlyIfStateExists(_stateId)
        returns (uint256, bool) 
    {   
        Transition[] storage transitions = states[_stateId].transitions;

        for(uint256 i = 0; i < transitions.length; i++) {
            if (keccak256(transitions[i].name) == keccak256(_name))
                return (i, true);
        }

        return (0, false);
    }
}