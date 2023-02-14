#!/bin/bash
network_path=etc/zeeve/fabric

mkdir ${network_path}/config/channel-artifacts
cp ./config/configtx.yaml $network_path/config/configtx.yaml

configtxgen_path=etc/zeeve/fabric-samples/bin/configtxgen
export FABRIC_CFG_PATH=$network_path/config

${configtxgen_path} -profile BaseGenesis -channelID system-channel -outputBlock $network_path/config/channel-artifacts/genesis.block

${configtxgen_path} -profile BaseChannel -channelID customchannel -outputCreateChannelTx $network_path/config/channel-artifacts/channel.tx

${configtxgen_path} -profile BaseChannel -channelID customchannel -outputAnchorPeersUpdate $network_path/config/channel-artifacts/org1MSPanchors.tx  -asOrg org1

kubectl create secret generic zeeve-genesis -n blockchain-org1 --from-file=$network_path/config/channel-artifacts/genesis.block