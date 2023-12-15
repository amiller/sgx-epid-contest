import subprocess
import eth_abi
import os
import sys
import json
import base64

RA_CLIENT_SPID = os.environ['RA_CLIENT_SPID']
RA_API_KEY = os.environ['RA_API_KEY']

if not RA_API_KEY:
    print("need to set the Intel EPID RA API KEY")
    sys.exit(1)

if len(sys.argv) < 2:
    print("usage: <addr> <message>")
    sys.exit(1)

cmd = f'gramine-sgx python main.py {sys.argv[1]} "{sys.argv[2]}"'
print(cmd)

quote = subprocess.check_output(cmd, shell=True)

fpname = './testquote'
with open('./testquote','wb') as fp:
    fp.write(quote)
    fp.flush()

cmd = f'gramine-sgx-ias-request report -g {RA_CLIENT_SPID} -k {RA_API_KEY} -q {fpname} -r ./datareport -s ./datareportsig'
out = subprocess.check_output(cmd, shell=True)

datareport = open('./datareport').read()
datareportsig = open('./datareportsig').read().strip()
obj = dict(report=json.loads(datareport), reportsig=datareportsig)
report = obj['report']
items = (report['id'].encode(),
         report['timestamp'].encode(),
         str(report['version']).encode(),
         report['epidPseudonym'].encode(),
         report['advisoryURL'].encode(),
         json.dumps(report['advisoryIDs']).replace(' ','').encode(),
         report['isvEnclaveQuoteStatus'].encode(),
         report['platformInfoBlob'].encode(),
         base64.b64decode(report['isvEnclaveQuoteBody']))
abidata = eth_abi.encode(["bytes", "bytes", "bytes", "bytes", "bytes", "bytes", "bytes", "bytes", "bytes"], items)
sig = base64.b64decode(obj['reportsig'])
print(eth_abi.encode(["bytes","bytes"], (abidata,sig)).hex())
