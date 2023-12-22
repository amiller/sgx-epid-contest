FROM gramineproject/gramine:v1.5

RUN apt-get update
RUN apt-get install -y jq build-essential python3 python3-pip
RUN pip install eth_abi

WORKDIR /workdir

RUN gramine-sgx-gen-private-key

# This should be associated with an acive IAS SPID in order for
# gramine tools like gramine-sgx-ias-request and gramine-sgx-ias-verify
ENV RA_CLIENT_SPID=51CAF5A48B450D624AEFE3286D314894
ENV RA_API_KEY=669244b3e6364b5888289a11d2a1726d
ENV RA_CLIENT_LINKABLE=1

# Now add our actual source
COPY Makefile README.md python.manifest.template main.py make_attestation.py ./

# Make and sign the gramine manifest
RUN make SGX=1

# CMD [ "gramine-sgx-sigstruct-view python.sig" ]
# CMD [ "gramine-sgx python" ]
CMD [ "bash" ]
