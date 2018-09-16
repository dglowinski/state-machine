pragma solidity ^0.4.24;

import "./openzeppelin/Ownable.sol";

/**
 * @title StateMachineStorage
 * @dev Contract defines storage structure of the state machine
 */
contract StateMachineStorage is Ownable {
    struct Func {
        address contractAddress;
        bytes32 signature;
    }

    struct Transition {
        string name;
        uint256 nextStateId;
        Func condition;
        Func trigger;
        bool auto;
    }
    
    struct State {
        uint256 id;
        string name;
        string[] autoTransitions;
        mapping(string => Transition) transitions;
    }

    mapping(uint256 => State) public states;
    uint256 public stateId;
}