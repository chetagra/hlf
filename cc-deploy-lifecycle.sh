network_path=etc/zeeve/fabric
peer_bin_path=etc/zeeve/fabric-samples/bin/peer

cd chaincode/packaging
tar cfz code.tar.gz connection.json
tar cfz marbles-org1.tgz code.tar.gz metadata.json
cp marbles-org1.tgz ../../marbles.tgz
rm -rf marbles-org1.tgz code.tar.gz
cd ../..

export CORE_PEER_TLS_CERT_FILE=$network_path/config/crypto-config/org1/peer-1org1/tls/server.crt
export CORE_PEER_TLS_KEY_FILE=$network_path/config/crypto-config/org1/peer-1org1/tls/server.key
export CORE_PEER_TLS_ROOTCERT_FILE=$network_path/config/crypto-config/org1/peer-1org1/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$network_path/config/crypto-config/org1/Admin-org1
export CORE_PEER_LOCALMSPID=org1MSP
export CORE_PEER_ADDRESS=minikube:30005
export CORE_PEER_TLS_ENABLED=true

export FABRIC_CFG_PATH=$PWD

${peer_bin_path} lifecycle chaincode install marbles.tgz

$peer_bin_path lifecycle chaincode queryinstalled

rm -rf marbles.tgz

docker build -t chaincode/marbles:1.0 ./chaincode

kubectl create -f chaincode/k8s

export CC_PACKAGE_ID=marbles02:0cc678db96ceaafea0588b0e674866ec7515fb7dba07301c65a6405c05aa165d

$peer_bin_path lifecycle chaincode approveformyorg -o minikube:30004 --channelID customchannel --name marbles-cc --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.org1.minikube.crt --init-required

$peer_bin_path lifecycle chaincode checkcommitreadiness --channelID customchannel --name marbles-cc --version 1.0 --sequence 1 --tls --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.org1.minikube.crt --output json --init-required

$peer_bin_path lifecycle chaincode commit --init-required  -o minikube:30004 --channelID customchannel --name marbles-cc --version 1.0 --sequence 1 --tls --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.org1.minikube.crt --peerAddresses minikube:30005 --tlsRootCertFiles $network_path/config/crypto-config/org1/peer-1org1/tls/ca.crt

$peer_bin_path lifecycle chaincode querycommitted --channelID customchannel --name marbles-cc --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.org1.minikube.crt 

$peer_bin_path chaincode invoke -o minikube:30004 --isInit --tls true --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.org1.minikube.crt -C customchannel -n marbles-cc --peerAddresses minikube:30005 --tlsRootCertFiles $network_path/config/crypto-config/org1/peer-1org1/tls/ca.crt -c '{"Args":["initMarble","marble1","blue","35","tom"]}'

$peer_bin_path chaincode query -o minikube:30004 --isInit --tls true --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.org1.minikube.crt -C customchannel -n marbles --peerAddresses minikube:30005 --tlsRootCertFiles $network_path/config/crypto-config/org1/peer-1org1/tls/ca.crt -c '{"Args":["readMarble","marble1"]}'

$peer_bin_path chaincode invoke -o minikube:30004 --tls true --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.org1.minikube.crt -C customchannel -n marbles-cc --peerAddresses minikube:30005 --tlsRootCertFiles $network_path/config/crypto-config/org1/peer-1org1/tls/ca.crt -c '{"Args":["initMarble","marble2","blue","35","tom"]}'
