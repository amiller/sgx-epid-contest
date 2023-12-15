import sys
from binascii import unhexlify

if len(sys.argv) < 3:
    print("usage: <addr> <message>")
    sys.exit(1)

addr = sys.argv[1]
assert len(addr) == 42
assert addr.startswith('0x')

message = sys.argv[2]
assert len(message) <= 44, "Total report size must be 64 bytes"

userReportData = unhexlify(addr[2:]) + message.rjust(44,' ').encode('utf-8')

with open('/dev/attestation/user_report_data','wb') as f:
    f.write(userReportData)

with open('/dev/attestation/quote','rb') as f:
    sys.stdout.buffer.write(f.read())
