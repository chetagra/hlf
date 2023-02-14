#!/bin/bash
network_path=etc/zeeve/fabric
peer_bin_path=etc/zeeve/fabric-samples/bin/peer

rm -rf core.yaml
cp ./config/core.yaml ./core.yaml

export CORE_PEER_TLS_CERT_FILE=$network_path/config/crypto-config/org1/peer-1org1/tls/server.crt
export CORE_PEER_TLS_KEY_FILE=$network_path/config/crypto-config/org1/peer-1org1/tls/server.key
export CORE_PEER_TLS_ROOTCERT_FILE=$network_path/config/crypto-config/org1/peer-1org1/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$network_path/config/crypto-config/org1/Admin-org1
export CORE_PEER_LOCALMSPID=org1MSP
export CORE_PEER_ADDRESS=minikube:30005
export CORE_PEER_TLS_ENABLED=true

export FABRIC_CFG_PATH=$PWD


${peer_bin_path} channel create -o minikube:30004 -c customchannel -f $network_path/config/channel-artifacts/channel.tx --tls --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.org1.minikube.crt --outputBlock $network_path/config/channel-artifacts/channel.block
${peer_bin_path} channel join -b $network_path/config/channel-artifacts/channel.block
${peer_bin_path} channel update -o minikube:30004 -c customchannel -f $network_path/config/channel-artifacts/org1MSPanchors.tx --tls --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.org1.minikube.crt