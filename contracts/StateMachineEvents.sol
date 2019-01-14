    
pragma solidity ^0.4.25;

contract StateMachineEvents {
    event _INSERT_STATE(address contract_address, string name);
    event _DELETE_STATE(address contract_address, string name);
    event _INSERT_TRANSITION(address contract_address, string name, string from_state, string to_state);
    event _DELETE_TRANSITION(address contract_address, string name);
}