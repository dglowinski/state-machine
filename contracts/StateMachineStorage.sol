pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

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