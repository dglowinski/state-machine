pragma solidity ^0.4.24;

import "./StateMachineStorage.sol";

contract PassTheBall is StateMachineStorage {
    
    uint256 internal constant gameDuration = 5;

    bytes32 internal constant startBlockSlot = keccak256("pdb_startBlock");

    bytes32 internal constant passesASlot = keccak256("pdb_passesA");
    bytes32 internal constant passesBSlot = keccak256("pdb_passesB");
    bytes32 internal constant passesCSlot = keccak256("pdb_passesC");

    //triggers
    function startGame() public {
        setVar(startBlockSlot, block.number);
    }

    function endGame() public {
        setVar(passesASlot, 0);
        setVar(passesBSlot, 0);
        setVar(passesCSlot, 0);
    }

    function passToA() public {
        setVar(passesASlot, getVar(passesASlot) + 1);
    }

    function passToB() public {
        setVar(passesBSlot, getVar(passesBSlot) + 1);
    }
    
    function passToC() public {
        setVar(passesBSlot, getVar(passesBSlot) + 1);
    }

    //conditions
    function timeOut() {
        require(block.number - getVar(startBlockSlot) > gameDuration, "Game ended");
    }

    function canPassToA() public {
        require(passAllowed(getVar(passesASlot)+1, getVar(passesBSlot), getVar(passesCSlot)), "Pass not allowed");
    }

    function canPassToB() public {
        require(passAllowed(getVar(passesASlot), getVar(passesBSlot)+1, getVar(passesCSlot)), "Pass not allowed");
    }

    function canPassToC() public {
        require(passAllowed(getVar(passesASlot), getVar(passesBSlot), getVar(passesCSlot)+1), "Pass not allowed");
    }

    function passAllowed(uint256 _a, uint256 _b, uint256 _c) internal pure returns (bool) {
        uint256 max = _a;
        uint256 min = _a;
        if(_b > max) max = _b; else min = _b;
        if(_c > max) max = _c;
        if(_c < min) min = _c;

        return max - min < 3;
    }

    //storage
    function setVar(bytes32 _slot, uint256 _passes) internal {
        bytes32 slot = _slot;
        assembly {
            sstore(slot, _passes)
        }
    }

    function getVar(bytes32 _slot) internal view returns(uint256 _passes) {
        bytes32 slot = _slot;
        assembly {
            _passes := sload(slot)
        }
    }
}