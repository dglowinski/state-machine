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
        
        states[_id] = State(_id, _name, new string[](0));
        if(stateId == 0) stateId = _id;
    }

    function deleteState(uint256 _id) external onlyOwner {
        require(stateId != _id, "Can't delete current state");
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
    ) 
        external 
        onlyOwner 
        onlyIfStateExists(_stateId) 
    {
        require(bytes(_name).length > 0, "Transition name required");
        require(bytes(states[_stateId].transitions[_name].name).length == 0, "Transition already exists");
        
        states[_stateId].transitions[_name] = Transition({
            name: _name,
            condition: Func(_conditionContract, _conditionSignature),
            trigger: Func(_triggerContract, _triggerSignature),
            auto: _auto,
            nextStateId: _nextStateId
        });

        if(_auto) states[_stateId].autoTransitions.push(_name);
    }

    function deleteTransition(uint256 _stateId, string _name) external onlyOwner {
        State storage state = states[_stateId];

        if(state.transitions[_name].auto) {
            uint256 autoIndex;
            for(uint256 i = 0; i < state.autoTransitions.length; i++) {
                if(keccak256(bytes(state.autoTransitions[i])) == keccak256(bytes(_name))) 
                    autoIndex = i;
            }

            state.autoTransitions[i] = state.autoTransitions[state.autoTransitions.length - 1];
            state.autoTransitions.length -= 1;
        }
        delete state.transitions[_name];
    }

    function getCurrentStateName() external view returns(string) {
        return states[stateId].name;
    }
}