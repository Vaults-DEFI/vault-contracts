// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

contract SimpleTest is Test {
    function setUp() public {
        console.log("Setting up the simple test...");
    }

    function testSimpleLog() public {
        console.log("Starting testSimpleLog");
        console.log("This is a test log.");
        console.log("Test completed.");
    }
}
