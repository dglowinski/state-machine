pragma solidity ^0.4.25;

import "./StringsLib.sol";
/**
 * @title StateMachineLib
 * @dev Contract defines storage structure and logic of a generic state machine
 */
library StateMachineLib {
    using StringsLib for *;

    struct Callback {
        address contractAddress;
        bytes callData;
        bool isDelegatecall;
    }

    struct Transition {
        string name;
        string nextState;
        Callback guard;
        Callback trigger;
    }
    
    struct State {
        string name;
        Callback onEnter;
        Callback onLeave;
        mapping(string => Transition) transitions;
        string[] transitionKeys;
    }

    struct Data {
        mapping(string => State) states;
        string[] stateKeys;
        string state;
    }

    modifier onlyIfStateExists(Data storage self, string _name) {
        require(
            bytes(self.states[_name].name).length > 0, 
            "StateMachineLib:onlyIfStateExists - State doesn't exist"
        );
        _;
    }

    modifier onlyIfValidCallback(Callback _callback) {
        require(
            _callback.contractAddress == address(0) && _callback.callData.length == 0 ||
            _callback.contractAddress != address(0) && _callback.callData.length >= 4,
            "StateMachineLib:onlyIfValidCallback - Callback is not valid"
        );
        _;
    }

    event TestBytes(bytes Bytes);
    event TestBytes1(bytes1 Bytes);
    event TestUint(uint256 Uint);
    event TestBool(bool Bool);
    
    function getAllStates(Data storage self) 
        internal
        view
        returns (string[])
    {
        return self.stateKeys;
    }
    
    function getAllStateTransitions(Data storage self, string _state) 
        internal
        view
        onlyIfStateExists(self, _state)
        returns (string[])
    {
        return self.states[_state].transitionKeys;
    }

    ///@dev Create a new state if not already exists. The first state created is the initial state.
    function addState(Data storage self, string _name, Callback _onEnter, Callback _onLeave) 
        internal
        onlyIfValidCallback(_onEnter)
        onlyIfValidCallback(_onLeave)
    {
        require(
            bytes(self.states[_name].name).length == 0, 
            "StateMachineLib:addState - State already exists"
        );
        
        self.states[_name] = State({
            name: _name,
            onEnter: _onEnter,
            onLeave: _onLeave,
            transitionKeys: new string[](0)
        });
        self.states[_name].transitionKeys.push(_name);

        if(bytes(self.state).length == 0) self.state = _name;
    }

    ///@dev Delete a state by name, unless it's current state
    function deleteState(Data storage self, string _name) 
        internal
        onlyIfStateExists(self, _name) 
    {
        require(
            keccak256(abi.encodePacked(self.state)) != keccak256(abi.encodePacked(_name)), 
            "StateMachineLib:deleteState - Can't delete current state"
        );
        
        delete self.states[_name];
        deleteFromArray(self.stateKeys, _name);
    }


    /**
    * @dev Define new transition for the state
    * @notice Transitions are invoked by name. First a guard call is executed and if
    * it returns true, a trigger call is executed and state is changed. 
    */
    function addTransition(
        Data storage self,
        string _name,
        string _fromState,
        string _nextState, 
        Callback _guard,
        Callback _trigger
    ) 
        internal 
        onlyIfStateExists(self, _fromState)  
        onlyIfStateExists(self, _nextState)
        onlyIfValidCallback(_guard)  
        onlyIfValidCallback(_trigger)
    {
        require(bytes(_name).length > 0, "StateMachineLib:addTransition - Transition name required");
        require(
            bytes(self.states[_fromState].transitions[_name].name).length == 0, 
            "Transition already exists"
        );
        
        self.states[_fromState].transitions[_name] = Transition({
            name: _name,
            guard: _guard,
            trigger: _trigger,
            nextState: _nextState
        });

        self.states[_fromState].transitionKeys.push(_name);
    }

    ///@dev Delete transition by state and name
    function deleteTransition(Data storage self, string _state, string _name) 
        internal
        onlyIfStateExists(self, _state)   
    {
        require(
            bytes(self.states[_state].transitions[_name].name).length > 0, 
            "StateMachineLib:deleteTransition - Transition doesn't exist"
        );
        delete self.states[_state].transitions[_name];
        deleteFromArray(self.states[_state].transitionKeys, _name);
    }

    //TODO refactor, readme about data layout in call
    function setupStateMachine(
        Data storage self,
        uint[] _counts,
        string _names,
        address[] _addresses,
        string _callData,
        bool[] _isDelegatecall
    ) 
        internal 
    {
        string memory delimString = ";";
        StringsLib.slice memory delim = delimString.toSlice();
        StringsLib.slice memory namesSlice = _names.toSlice();
        string[] memory namesArray = new string[](namesSlice.count(delim) + 1);
        for(uint i = 0; i < namesArray.length; i++) {
            namesArray[i] = namesSlice.split(delim).toString();
        }

        StringsLib.slice memory callDataSlice = _callData.toSlice();
        bytes[] memory callDataArray = new bytes[](callDataSlice.count(delim) + 1);
        for(i = 0; i < callDataArray.length; i++) {
            callDataArray[i] = convertUtf8StringToBytes(callDataSlice.split(delim).toString());
        }

        setupStates(self, _counts[0], namesArray, _addresses, callDataArray, _isDelegatecall);
        setupTransitions(self, _counts[0], _counts[1], namesArray, _addresses, callDataArray, _isDelegatecall);
    }

    function setupStates(
        Data storage self,
        uint _statesCount,
        string[] _names,
        address[] _addresses,
        bytes[] _callData,
        bool[] _isDelegatecall
    )
        internal
    {
        for(uint i = 0; i < _statesCount; i++) {
            addState(
                self, 
                _names[i], 
                createCallback(_addresses[i * 2], _callData[i * 2], _isDelegatecall[i * 2]), 
                createCallback(_addresses[i * 2 + 1], _callData[i * 2 + 1], _isDelegatecall[i * 2 + 1])
            );
        }

    }

    function setupTransitions(
        Data storage self,
        uint _statesCount,
        uint _transitionsCount,
        string[] _names,
        address[] _addresses,
        bytes[] _callData,
        bool[] _isDelegatecall
    )
        internal
    {
        uint callbackIndex;
        uint nameIndex;

        for(uint i = 0; i < _transitionsCount; i++) {
            callbackIndex = 2 * _statesCount + 2 * i;
            nameIndex = _statesCount + _transitionsCount + 2 * i;

            addTransition(
                self, 
                _names[_statesCount + i], 
                _names[nameIndex], 
                _names[nameIndex + 1], 
                createCallback(_addresses[callbackIndex], _callData[callbackIndex], _isDelegatecall[callbackIndex]), 
                createCallback(_addresses[callbackIndex + 1], _callData[callbackIndex + 1], _isDelegatecall[callbackIndex + 1])
            );
        }
    }

    /**
    * @dev Perform state transition
    * @return true if transition was successful
    */
    function transition(Data storage self, string _name) 
        internal
        returns (bool) 
    {
        require(
            bytes(self.states[self.state].transitions[_name].name).length > 0, 
            "StateMachineLib:transition - Transition doesn't exist in current state"
        );
        Transition storage trans = self.states[self.state].transitions[_name];
        
        if(!execCallback(trans.guard)) {
            return false;
        }
       
        execCallback(self.states[self.state].onLeave);
        
        execCallback(trans.trigger);

        self.state = trans.nextState;

        execCallback(self.states[self.state].onEnter);

        return true;
    }

    // TODO: if address 0 and calldata valid -> address = this
    function createCallback(address _contractAddress, bytes _callData, bool _isDelegatecall) 
        internal
        view
        returns (Callback memory)
    {
        return Callback({
            contractAddress: _callData.length >= 4 && _contractAddress == address(0) ? address(this) : _contractAddress,
            callData: _callData,
            isDelegatecall: _isDelegatecall
        });
    }

    ///@dev Execute call or delegate call
    ///@return true if the call did not revert 
    function execCallback(Callback _callback) 
        internal 
        returns (bool) 
    {
        return _callback.contractAddress == address(0) ||
            _callback.isDelegatecall ? 
            _callback.contractAddress.delegatecall(_callback.callData)
            : _callback.contractAddress.call(_callback.callData);
    }

    function deleteFromArray(string[] storage _arr, string _item) 
        internal
    {
        for(uint256 i = 0; i < _arr.length; i++) {
            if(keccak256(abi.encodePacked(_arr[i])) == keccak256(abi.encodePacked(_item))) {
                _arr[i] = _arr[_arr.length - 1];
                _arr.length--;
                return;
            }
        }
    }

    function convertUtf8StringToBytes(string memory str) 
        internal 
        pure 
        returns (bytes) 
    {    
        bytes memory input = bytes(str);
        bytes memory ret = new bytes(input.length/2);
        uint index = 0;
        for (uint i = 0; i < input.length; i += 2) {
            ret[index] = convertUtf8CharToByte(input[i]) << 4;
            ret[index] = ret[index] | convertUtf8CharToByte(input[i+1]);
            index++;
        }
        return ret;
    }
    
    function convertUtf8CharToByte(bytes1 char) 
        internal 
        pure 
        returns (bytes1) 
    {
        if(char <= 0x39) {
            return char ^ 0x30;
        } else {
            if(char == 0x61) return 0x0a;
            if(char == 0x62) return 0x0b;
            if(char == 0x63) return 0x0c;
            if(char == 0x64) return 0x0d;
            if(char == 0x65) return 0x0e;
            if(char == 0x66) return 0x0f;
        }
    }
}