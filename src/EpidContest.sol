// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;
import "solidity-stringutils/strings.sol";
import { BytesUtils } from "ens-contracts/dnssec-oracle/BytesUtils.sol";
import { JSONBuilder2 } from "src/JSONBuilder.sol";
import {RAVE} from "rave/RAVE.sol";

import "forge-std/console.sol";

contract EpidContest is JSONBuilder2, RAVE {
    using strings for *;
    using BytesUtils for *;

    //////////////////////////
    // Attestation checker
    //////////////////////////

    // Check the attestation and return the relevant parts
    function verify_epid(bytes memory attestation) public view
    returns(string memory epidGroupID, bytes memory) {
	
	// Decode the outer layer, report and sig separately
	(bytes memory report, bytes memory sig) = abi.decode(attestation, (bytes, bytes));
	    
	// Parse to RAVE structure and regenerate the canonical JSON
        (Values2 memory reportValues, bytes memory reportBytes) = _buildReportBytes2(report);
        if (!this.verifyReportSignature(reportBytes, sig, signingMod, signingExp)) {
            revert BadReportSignature();
        }

        // quote body is already base64 decoded
        bytes memory quoteBody = reportValues.isvEnclaveQuoteBody;
        assert(quoteBody.length == QUOTE_BODY_LENGTH);

	// Extract the group id
	epidGroupID = decode_gid(reportValues.platformInfoBlob);

        // Bypass mrenclave check - any enclave will do!
	// Bypass status check
	// Bypass mrsigner check

        // Verify report's <= 64B payload matches the expected
        bytes memory payload = quoteBody.substring(PAYLOAD_OFFSET, PAYLOAD_SIZE);
	//require(bytes(iToHex(payload)).equals(bytes(userReportData)));

	return (epidGroupID, payload);
    }


    ///////////////////////////
    // Contest functionality
    ///////////////////////////

    // Contribute to the prize pool
    uint public prizepool;
    function donate() public payable {
	prizepool += msg.value;
    }

    // The prize pool is rewarded divided among 20 winning tickets
    uint public constant MAXTICKETS = 20;
    uint public tickets_remaining = MAXTICKETS;

    // How much has each winner already withdrawn?
    mapping (address => uint) public withdrawals;

    // How many tickets has each user earned?
    mapping (address => uint) public tickets;

    // How much can I withdraw?
    function balance(address addr) public returns(uint) {
	return (prizepool / MAXTICKETS) * tickets[addr] - withdrawals[addr];
    }
    
    // Withdraw as much as I can
    function withdraw() public {
	uint amt = balance(msg.sender);
	require(amt > 0);
	withdrawals[msg.sender] += amt;
	payable(msg.sender).transfer(amt);
    }    

    // For each groupID, has anyone won? What did they say?
    mapping(string => address) internal winners;
    mapping(string => string)  internal logbook;
    
    function getWinner(string memory gid) public view returns(address) {
	return winners[gid];
    }

    function getLogbook(string memory gid) public view returns(string memory) {
	return logbook[gid];
    }
    
    // For the bonus incentive feature: give a little extra if two weeks have elapsed
    uint constant public BONUS_TIME = 2 weeks;
    uint public lastClaimed;
    
    function currentBonus() public view returns(uint) {
	if (lastClaimed == 0) return 0;
	return (block.timestamp - lastClaimed) / BONUS_TIME;
    }

    // Check a new applicant
    event RewardClaimed(string gid, address addr, string message);
    function enter_contest(bytes memory attestation) public {
	// Only while supplies last
	require(tickets_remaining > 0);
	
	// First check the attestation
	(string memory epidGroupID, bytes memory userReportData) = verify_epid(attestation);

	// Each Group ID can only be claimed once
	require(winners[epidGroupID] == address(0x0));

	// Record the winner
	address addr = address(bytes20(userReportData.substring(0, 20)));	
	string memory message = string(userReportData.substring(20,44));
	winners[epidGroupID] = addr;
	logbook[epidGroupID] = message;

	// How many shares do we win? Check the bonus condition
	uint win = 1 + currentBonus();
	if (win > tickets_remaining) win = tickets_remaining;
	tickets_remaining -= win;
	tickets[addr] += win;
	lastClaimed = block.timestamp;

	// Log message
	emit RewardClaimed(epidGroupID, addr, message);
    }    

    ///////////////////////////////
    // Attestation helper functions
    ///////////////////////////////

    // Build a userReportData from an address and a string, the
    // format used for claiming contest rewards and signing the book
    function userdata_tool(address addr, string memory message)
    public pure returns(string memory) {
	// Produces a hex string (20 bytes addr) (44 bytes msg)
	bytes memory m = bytes(message);
	require(m.length <= 44);
	bytes memory padding = new bytes(44 - m.length);
	bytes memory s = abi.encodePacked(addr, padding, m);
	return iToHex(s);
    }    

    // Gramine produces the report and reportsig separately
    function combine_report_sig(bytes memory report, bytes memory sig)
    public pure
    returns (bytes memory) {
	return abi.encode(report, sig);
    }

    // Extract the Epid Group ID from the pib
    function decode_gid(bytes memory platformInfoBlob)
    public pure returns(string memory) {
	// Decode the group ID. This is bytes [37:41], reverse order
	bytes memory m = new bytes(8);
	for (uint i = 0; i < 4; i++) {
	    m[7-2*i] = platformInfoBlob[75+2*i];
	    m[6-2*i] = platformInfoBlob[74+2*i];	    
	}
	return string(m);
    }

    // Helper function for rendering an attestation in the explorer
    function parse_epid_report(bytes memory attestation) public pure returns(
	string memory id,
        string memory timestamp,
        string memory version,
        string memory epidPseudonym,
        string memory advisoryURL,
        string memory advisoryIDs,
        string memory isvEnclaveQuoteStatus,
	string memory platformInfoBlob,
        string memory isvEnclaveQuoteBody,
	string memory userReportData,
	string memory epidGroupID) {
	// Decode the outer layer, report and sig separately
	(bytes memory report, bytes memory sig) = abi.decode(attestation, (bytes, bytes));

	// Parse to RAVE structure and regenerate the canonical JSON
        (Values2 memory reportValues, bytes memory reportBytes) = _buildReportBytes2(report);

        userReportData = iToHex(reportValues.isvEnclaveQuoteBody.substring(PAYLOAD_OFFSET, PAYLOAD_SIZE));
	id = string(reportValues.id);
	timestamp = string(reportValues.timestamp);
	version = string(reportValues.version);
	epidPseudonym = string(reportValues.epidPseudonym);
	advisoryURL = string(reportValues.advisoryURL);
	advisoryIDs = string(reportValues.advisoryIDs);
	isvEnclaveQuoteStatus = string(reportValues.isvEnclaveQuoteStatus);
	platformInfoBlob = string(reportValues.platformInfoBlob);
	isvEnclaveQuoteBody = iToHex(reportValues.isvEnclaveQuoteBody);
	epidGroupID = decode_gid(reportValues.platformInfoBlob);
    }

    function iToHex(bytes memory buffer) public pure returns (string memory) {
        // Fixed buffer size for hexadecimal convertion
        bytes memory converted = new bytes(buffer.length * 2);
        bytes memory _base = "0123456789abcdef";
        for (uint256 i = 0; i < buffer.length; i++) {
            converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
            converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
        }
        return string(converted);
    }    

    // Hardcoded Intel public key
    bytes constant signingMod = hex"a97a2de0e66ea6147c9ee745ac0162686c7192099afc4b3f040fad6de093511d74e802f510d716038157dcaf84f4104bd3fed7e6b8f99c8817fd1ff5b9b864296c3d81fa8f1b729e02d21d72ffee4ced725efe74bea68fbc4d4244286fcdd4bf64406a439a15bcb4cf67754489c423972b4a80df5c2e7c5bc2dbaf2d42bb7b244f7c95bf92c75d3b33fc5410678a89589d1083da3acc459f2704cd99598c275e7c1878e00757e5bdb4e840226c11c0a17ff79c80b15c1ddb5af21cc2417061fbd2a2da819ed3b72b7efaa3bfebe2805c9b8ac19aa346512d484cfc81941e15f55881cc127e8f7aa12300cd5afb5742fa1d20cb467a5beb1c666cf76a368978b5";
    bytes constant signingExp = hex"0000000000000000000000000000000000000000000000000000000000010001";

}
