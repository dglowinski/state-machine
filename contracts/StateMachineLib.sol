pragma solidity ^0.4.25;


/**
 * @title StateMachineLib
 * @dev Contract defines storage structure and logic of a generic state machine
 */
library StateMachineLib {
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
            keccak256(self.state) != keccak256(_name), 
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

    //TODO refactor
    function setupStatesAndTransitions(
        Data storage self,
        uint[] _counts,
        string[] _names,
        address[] _addresses,
        bytes[] _callData,
        bool[] _isDelegatecall
    ) 
        internal 
    {
        setupStates(self, _counts[0], _names, _addresses, _callData, _isDelegatecall);
        setupTransitions(self, _counts[0], _counts[1], _names, _addresses, _callData, _isDelegatecall);
        
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
        string memory name;
        address contractAddress;
        Callback memory callback1;
        Callback memory callback2;

        for(uint i = 0; i < _statesCount; i++) {
            name = _names[i];
            callback1.contractAddress = _addresses[i * 2];
            callback1.callData = _callData[i * 2];
            callback1.isDelegatecall = _isDelegatecall[i * 2];

            callback2.contractAddress = _addresses[i * 2 + 1];
            callback2.callData = _callData[i * 2 + 1];
            callback2.isDelegatecall = _isDelegatecall[i * 2 + 1];

            addState(self, name, callback1, callback2);
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
        string memory name;
        address contractAddress;
        Callback memory callback1;
        Callback memory callback2;
        uint pnt;
        uint pnt1;

        for(uint i = 0; i < _transitionsCount; i++) {
            name = _names[_statesCount + i];
            pnt = 2 * _statesCount + 2 * i;
            callback1.contractAddress = _addresses[pnt];
            callback1.callData = _callData[pnt];
            callback1.isDelegatecall = _isDelegatecall[pnt];

            pnt++;
            callback2.contractAddress = _addresses[pnt];
            callback2.callData = _callData[pnt];
            callback2.isDelegatecall = _isDelegatecall[pnt];
            pnt1 = _statesCount + _transitionsCount + 2 * i + 1;

            addTransition(self, name, _names[pnt - 1], _names[pnt1], callback1, callback2);
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
            if(keccak256(_arr[i]) == keccak256(_item)) {
                _arr[i] = _arr[_arr.length - 1];
                _arr.length--;
                return;
            }
        }
    }
}