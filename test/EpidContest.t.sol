// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;
import "solidity-stringutils/strings.sol";
import { BytesUtils } from "ens-contracts/dnssec-oracle/BytesUtils.sol";

import "forge-std/console2.sol";
import "forge-std/Test.sol";

import { EpidContest } from "src/EpidContest.sol";

contract EpidContestTest is Test, EpidContest {
    using strings for *;
    using BytesUtils for *;

    function testAttestation() public {
	string memory s = vm.readFile("test/fixtures/epidreport.hex");
	bytes memory attestation = vm.parseBytes(s);
	(string memory epidGroupID, bytes memory userReportData) = verify_epid(attestation);
	bytes memory groundtruth = hex"9113b0be77ed5d0d68680ec77206b8d587ed40679b71321ccdd5405e4d54a6820000000000000000000000000000000000000000000000000000000000000000";
	assertEq(userReportData, groundtruth);
	assertEq(epidGroupID, "B00C0000");

	address a = address(0x9113B0bE77ed5d0D68680ec77206B8d587eD4067);	
	string memory userdata = userdata_tool(a, "hi");
	//console.log(userdata);
    }


    function testClaim() public {
	string memory s = vm.readFile("test/fixtures/epidreport.hex");
	bytes memory attestation = vm.parseBytes(s);
	this.donate{value: 1000 ether}();

	// Win the contest 
	this.enter_contest(attestation);
	address a = address(0x9113B0bE77ed5d0D68680ec77206B8d587eD4067);
	assertEq(winners["B00C0000"], a);
	
	// We should have won 10 eth now
	console.logUint(a.balance);
	assertEq(balance(a), 10 ether);
	assertEq(tickets_remaining, MAXTICKETS-1);

	// Check withdrawal
	vm.prank(a);
	this.withdraw();
	assertEq(balance(a), 0);
	assertEq(a.balance, 10 ether);

	// Advance the time a week to see increased bonus
	assertEq(currentBonus(), 0);
	
	vm.warp(block.timestamp + 1 days);
	assertEq(currentBonus(), 0);
	
	vm.warp(block.timestamp + 1 weeks);
	assertEq(currentBonus(), 1);
	
	// Adding to the prize pool increases balance for everyone
	this.donate{value:2000 ether}();
	assertEq(balance(a), 20 ether);
    }
    
}
