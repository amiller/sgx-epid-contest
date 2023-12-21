## Generate signed manifest

- notice that we're explicitely calling `RA_CLIENT_LINKABLE=1` to have the field `epidPseudonym` populated in the attestation report
- the SPID value specified in `RA_CLIENT_SPID` must also be a **linkable** key

```
make PYTHON=python3.11 SGX=1 RA_TYPE=epid RA_CLIENT_SPID=XXX RA_CLIENT_LINKABLE=1
```

## Obtain attestation encoded for Ethereum

```
RA_API_KEY=xxx python3 scripts/make_attestation.py 0xdeadbeef
```

