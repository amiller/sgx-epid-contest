# Good Riddance to EPID Pre-Deprecation Memorial Contest

On-chain verification of SGX remote attestations is the hot [new thing](https://collective.flashbots.net/t/demystifying-remote-attestation-by-taking-it-on-chain/2629/2)! 

Here’s a summary of on-chain smart contract verifiers for Intel SGX attestation:
|   |	Solidity | CosmWasm |
|---|----|----|
EPID | (nearly deprecated)	[Puffer-RAVE](https://github.com/PufferFinance/rave/)	 |	Gabe's [epid-verifier-contract](https://github.com/Riderfighter/epid-verifier-contract/tree/main/src)
DCAP | (the way)		[Automata-DCAP](https://github.com/automata-network/automata-dcap-v3-attestation)	| (?)

Although some of these efforts focus on EPID, we know that EPID will be [deprecated entirely soon ](https://www.intel.com/content/www/us/en/developer/articles/technical/software-security-guidance/resources/sgx-ias-using-epid-eol-timeline.html)

> “Intel plans to end of life (EOL) this service April 2, 2025.”

So to send it on its way, we're going to do something fun and totally new... the first ever TEE-based on-chain contest! First person to interact with the contract using a different family of SGX-enabled processors gets to win a share of a prize pool. You also get to sign the logbook, leaving a description of your CPU type by default.

The contest contract is deployed on Optimism: https://optimistic.etherscan.io/address/0x490A428b0301D61DB6eD45eddc55d615F2EA9F75

**First: what’s an attestation?** It’s generated from a trusted execution environment (TEE) like Intel SGX. It is kind of like a signature. It works like this: an application can specify a message (a user report data) and request an attestation. The resulting attestation is basically like a signature over BOTH the message AND the program binary of the enclave that created it. You can verify the signature against Intel’s public key. Cool. 

Here's a sample attestation in a json format: [(sample attestation)](https://gist.githubusercontent.com/amiller/411b85cfe0247807827789b06e7e65cd/raw/142d230c1ee95f054d4c5af886074aac0129bc07/sample%2520attestation) and included is a sample attestation encoded how the RAVE verifier likes to accept it: [./test/fixtures/epidreport.hex](https://github.com/amiller/sgx-epid-contest/blob/master/test/fixtures/epidreport.hex)

**What do you mean by “family of SGX processors”?** The attestation also includes some information associated with the type of processor. In the case of EPID, it is the “Epid Group ID” field (which is inside the “platformInfoBlob” that you can see in the sample). The mapping is not exactly 1-to-1 though. Some similar processors are part of the same group. Sometimes associated with a major BIOS update (like after the infamous sgx vulnerabilities), a new group ID gets assigned. Read more about this in the https://sgx.fail/ paper! But ultimately it’s a mystery because Intel doesn’t publish information about the EPID Group IDs.

**Why is EPID being deprecated?** It’s an unnecessary bottleneck on Intel. It means that someone has to interact with Intel every time a device carries out remote attestation. This is burdensome on Intel, so they use API keys they can revoke if they detect misuse. For decentralized permissionless applications, this creates a huge bottleneck of trust on Intel that just doesn’t have to be there. Once EPID is deprecated, we’ll have to use DCAP, which doesn’t suffer from these problems. 

Gramine has a nice description of the issue: https://gramine.readthedocs.io/en/stable/attestation.html#remote-attestation-flows-for-epid-and-dcap

**Why did they do it this way?** It’s hard to explain to be honest, but it makes a lot more sense if you remember that SGX was originally designed with DRM on consumer devices (like bluray players on your laptop) and application developers had weak infrastructure. Of course now the app developers and clouds are providing infrastructure, Intel just doesn’t need to be in the middle. 

**So here are the rules of the contest:**
- There are 20 shares available to win. Initially all are unassigned.
- Donations to the prize pool can be added at any time. Each share is entitled to 1/20 of the total pool.
- Whoever is the first to register with the contract for a given EPID Group ID wins at least 1 of the remaining shares (if any remain), and gets to post a message (just 44 bytes, since it has to fit in the fucking user report data next to an address).
- Each 2 weeks that go by since the last claim, we add 1 share to a bonus pool, all of which goes to the next person to register and win.

* **WARNING**: This contract has not been audited at all. Maybe it doesn't work. Contribute to the prize pool at your own risk.*

**How can I check my existing processor to see if my group ID is unclaimed?**
First to see if your processor is SGX compatible, you can [look it up in the catalog](https://ark.intel.com/content/www/us/en/ark.html#@Processors).
You may also need to enable SGX in your BIOS, and it’s not supported by all chipsets even if the processor is! On Linux you need to install a kernel module or something. But there are plenty of existing tutorials, and it’s a contest after all.

If you can run `is-sgx-available` and you see `SGX1: ... true` and `AESMD installed: OK`, then SGX is going to work. For Windows I don’t know how to help you, just wipe it and install gnu slash linux.

To actually generate an attestation and see your Group ID, we provide a sample enclave that you can run with Gramine. (See the ./sample-enclave directory). Regardless, you need to follow some of the setup instructions from Gramine outside of docker, like installing the SGX device driver and kernel module on the host machine.

**How does the smart contract contest work?**
The prize system is implemented in Solidity.

Since we just want to see the Group ID, we don’t check anything about the attestation, not even the `mrenclave`. Even `GROUP_OUT_OF_DATE` is considered OK (this is what it shows if you haven't upgraded your BIOS and are still vulnerable to prior problems). We use the 64-byte user report data field to determine where the reward goes and to sign the logbook.

**Now I really want to take this contest seriously, how do I know what processors to hunt for?**
Dunno. Here are a few possible strategies we thought of, maybe chat gpt will help you think of more:
- Find random old laptops and see if you can get ‘is-sgx-available’ to say ok.
- Maybe you are the first person to try it on Azure or OVH
- Lie about your processor type when you sign the logbook? 
- Maybe you already ran an SGX sample application on an old machine? If so you could probably claim one prize, then update your BIOS, then claim it again!!
- Wait for the next TCB Recovery. If we have one before EOL, where you can be the first to claim the new group ID for your processor family
- Maybe you can grief the contract using historical SGX attestations found online? It looks like RAVE [doesn't check expiry time yet](https://github.com/PufferFinance/rave/blob/84f3e6f/src/X509Verifier.sol#L149)

To test the contracts:
```shell
$  forge build
$  forge test
```

Authors: @amiller and @riderfighter

We thank [MASK Network](https://mask.io/) for a grant to make this open source project possible.