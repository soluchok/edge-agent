#!/bin/sh
#
# Copyright SecureKey Technologies Inc. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -e


echo "Generating edge-agent Test PKI"

cd /opt/workspace/edge-agent
mkdir -p test/bdd/fixtures/keys/tls
tmp=$(mktemp)
echo "subjectKeyIdentifier=hash
authorityKeyIdentifier = keyid,issuer
extendedKeyUsage = serverAuth
keyUsage = Digital Signature, Key Encipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = localhost
DNS.2 = *.trustbloc.local
DNS.3 = testnet.orb.local
DNS.4 = hydra
DNS.5 = *.example.com
DNS.6 = user-ui-agent.example.com
DNS.7 = user-agent.example.com
DNS.8 = second-ui-user-agent.example.com
DNS.9 = second-user-agent.example.com
DNS.10 = edge.router.agent.example.com
DNS.11 = uni-resolver-web.example.com
DNS.12 = edv-oathkeeper-proxy
DNS.13 = bdd-edv-oathkeeper-proxy" >> "$tmp"

CERT_CA="test/bdd/fixtures/keys/tls/ec-cacert.pem"
if [ ! -f "$CERT_CA" ]; then
#create CA
openssl ecparam -name prime256v1 -genkey -noout -out test/bdd/fixtures/keys/tls/ec-cakey.pem
openssl req -new -x509 -key test/bdd/fixtures/keys/tls/ec-cakey.pem -subj "/C=CA/ST=ON/O=Example Internet CA Inc.:CA Sec/OU=CA Sec" -out $CERT_CA
else
    echo "Skipping CA generation - already exists"
fi

#create TLS creds
openssl ecparam -name prime256v1 -genkey -noout -out test/bdd/fixtures/keys/tls/ec-key.pem
openssl req -new -key test/bdd/fixtures/keys/tls/ec-key.pem -subj "/C=CA/ST=ON/O=Example Inc.:edge-agent/OU=edge-agent/CN=localhost" -out test/bdd/fixtures/keys/tls/ec-key.csr
openssl x509 -req -in test/bdd/fixtures/keys/tls/ec-key.csr -CA test/bdd/fixtures/keys/tls/ec-cacert.pem -CAkey test/bdd/fixtures/keys/tls/ec-cakey.pem -CAcreateserial -extfile "$tmp" -out test/bdd/fixtures/keys/tls/ec-pubCert.pem -days 365

#create session cookie keys
mkdir -p test/bdd/fixtures/keys/session_cookies
openssl rand -out test/bdd/fixtures/keys/session_cookies/auth.key 32
openssl rand -out test/bdd/fixtures/keys/session_cookies/enc.key 32
openssl rand 32 | base64 | sed 's/+/-/g; s/\//_/g' > test/bdd/fixtures/keys/tls/service-lock.key

mkdir -p test/bdd/fixtures/keys/device
openssl ecparam -name prime256v1 -genkey -noout -out test/bdd/fixtures/keys/device/ec-cakey.pem
openssl req -new -x509 -key test/bdd/fixtures/keys/device/ec-cakey.pem -subj "/C=CA/ST=ON/O=Example Auth Device Inc.:CA Sec/OU=CA Sec" -out test/bdd/fixtures/keys/device/ec-cacert.pem

echo "done generating edge-agent PKI"
