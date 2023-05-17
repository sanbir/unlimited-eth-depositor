// SPDX-FileCopyrightText: 2023 P2P Validator <info@p2p.org>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "../src/P2pOrgUnlimitedEthDepositor.sol";
import "./interfaces/CheatCodes.sol";

contract CounterTest is Test {
    CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    P2pOrgUnlimitedEthDepositor public depositor;

    function setUp() public {
        cheats.createSelectFork("mainnet", 17279788);
        depositor = new P2pOrgUnlimitedEthDepositor(true);
    }

    function testDepositEther() public {
        depositor.deposit{value: 96 ether}();
        assertEq(depositor.balanceOf(address(this)), 96 ether);
    }
}
