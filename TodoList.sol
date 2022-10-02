pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract TodoList {

    struct Todo {
        string text;
        bool completed;
    }

    Todo[] public todos;
    
    //TODO List Functions
    
    function create(string calldata _text) external {
        todos.push(Todo({
            text : _text,
            completed : false
        }));            
    }

    function updateText(uint _index, string calldata _text) external {
        todos[_index].text = _text;
    }

    function get(uint _index) external view returns(string memory , bool) {
        Todo memory todo = todos[_index];
        return (todo.text, todo.completed);                
    }

    function togleCompleted(uint _index) external {
        todos[_index].completed = !todos[_index].completed;
    }
}
