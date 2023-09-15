// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Auth {
    //权限
    mapping (address => uint256) internal _auth;

    event Admin(address indexed usr);
    event Permission(address indexed usr);
    event Deny(address indexed usr);

    function addPermission(address to_) external auth {
        _auth[to_] = 2;
        emit Permission(to_);
    }

    function deny(address usr) external auth {
        _auth[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(_auth[msg.sender] == 1, "not-authorized");
        _;
    }

    modifier permission {
        require(_auth[msg.sender] == 2 || _auth[msg.sender] == 1, "no-permission");
        _;
    }

}