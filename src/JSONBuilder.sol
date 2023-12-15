// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;
import { Base64 } from "openzeppelin/utils/Base64.sol";

contract JSONBuilder2 {
    struct Values2 {
        bytes id;
        bytes timestamp;
        bytes version;
        bytes epidPseudonym;
        bytes advisoryURL;
        bytes advisoryIDs;
        bytes isvEnclaveQuoteStatus;
	bytes platformInfoBlob;	
        bytes isvEnclaveQuoteBody;
    }

    function buildJSON2(Values2 memory values) public pure returns (string memory json) {
        json = string(
            abi.encodePacked(
                '{"id":"',
                values.id,
                '","timestamp":"',
                values.timestamp,
                '","version":',
                values.version,
                ',"epidPseudonym":"',
                values.epidPseudonym
            )
        );
        json = string(
            abi.encodePacked(
                json,
                '","advisoryURL":"',
                values.advisoryURL,
                '","advisoryIDs":',
                values.advisoryIDs,
                ',"isvEnclaveQuoteStatus":"',
                values.isvEnclaveQuoteStatus,
                '","platformInfoBlob":"',
                values.platformInfoBlob,
                '","isvEnclaveQuoteBody":"',
                values.isvEnclaveQuoteBody,
                '"}'
            )
        );
    }

    function _buildReportBytes2(bytes memory encodedReportValues)
        internal
        pure
        returns (Values2 memory reportValues, bytes memory reportBytes)
    {
        // Decode the report JSON values
        (
            bytes memory id,
            bytes memory timestamp,
            bytes memory version,
            bytes memory epidPseudonym,
            bytes memory advisoryURL,
            bytes memory advisoryIDs,
            bytes memory isvEnclaveQuoteStatus,
	    bytes memory platformInfoBlob,
            bytes memory isvEnclaveQuoteBody
        ) = abi.decode(encodedReportValues, (bytes, bytes, bytes, bytes, bytes, bytes, bytes, bytes, bytes));

        // Assumes the quote body was already decoded off-chain
        bytes memory encBody = bytes(Base64.encode(isvEnclaveQuoteBody));

        // Pack values to struct
        reportValues = Values2(
            id, timestamp, version, epidPseudonym, advisoryURL, advisoryIDs, isvEnclaveQuoteStatus, platformInfoBlob, encBody
        );

        // Reconstruct the JSON report that was signed
        reportBytes = bytes(buildJSON2(reportValues));

        // Pass on the decoded value for later processing
        reportValues.isvEnclaveQuoteBody = isvEnclaveQuoteBody;
    }    
}
