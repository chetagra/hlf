#!/bin/bash
# sudo cp -r ./etc/zeeve/fabric-samples/bin/* /usr/bin
absolute_value()
{
number=$number
absolute_value=0
element=$(( $absolute_value-$number ))
}

addApplicationTls() {
org_name=$p
component=$comp
number=$number
absolute_value $number
echo $element
domain=$1
channel=mychannel
network_path=etc/zeeve/fabric/$2
TLS_FILE=../../crypto-config/$org_name/new_certs/$component-$number$org_name/tls/server.crt
peer_bin_path=/usr/bin/peer
configtxlator_path=/usr/bin/configtxlator
export port=443
export CORE_PEER_TLS_CERT_FILE=$network_path/config/crypto-config/$org_name/$component-$number$org_name/tls/server.crt
export CORE_PEER_TLS_KEY_FILE=$network_path/config/crypto-config/$org_name/$component-$number$org_name/tls/server.key
export CORE_PEER_TLS_ROOTCERT_FILE=$network_path/config/crypto-config/TlsCaCerts/tlsca.$org_name.$domain.crt
export CORE_PEER_MSPCONFIGPATH=$network_path/config/crypto-config/$org_name/Admin-$org_name
export CORE_PEER_LOCALMSPID=${org_name}MSP
export CORE_PEER_ADDRESS=$component$number.$org_name.$domain:$port
export CORE_PEER_TLS_ENABLED=true
mkdir $network_path/config/channel-artifacts/application_channel
set=true
val=1
var=1
while [ $set ];
do
    $peer_bin_path channel fetch config $network_path/config/channel-artifacts/application_channel/config_block.pb -o $component$number.$org_name.$domain:$port -c $channel --tls --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.$org_name.$domain.crt
    var=$(echo "$?")
    if [[ $val -eq 3  || $var -eq 0 ]] 
    then
        break
    fi
    sleep 10
    val=$((val+1))
done
if [[ $var -ne 0 ]] 
then
    exit
fi
echo "$channel fetched using $component$number"
cd $network_path/config/channel-artifacts/application_channel
$configtxlator_path proto_decode --input config_block.pb --type common.Block --output syschannel_config.json 
cat syschannel_config.json | jq .data.data[0].payload.data.config > syschannel_config_config.json
cat syschannel_config.json | jq .data.data[0].payload.data.config > syschannel_config_config_original.json
tls_cert=$(base64 --wrap=0 $TLS_FILE)
jq --arg cert "${tls_cert}" --argjson element $element '.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters[$element].client_tls_cert = $cert' syschannel_config_config.json > temp.json && cp temp.json syschannel_config_config.json
jq --arg cert "${tls_cert}" --argjson element $element '.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters[$element].server_tls_cert = $cert' syschannel_config_config.json > temp.json && cp temp.json syschannel_config_config.json
$configtxlator_path proto_encode --input syschannel_config_config_original.json --type common.Config --output syschannel_config_config_original.pb
$configtxlator_path proto_encode --input syschannel_config_config.json --type common.Config --output syschannel_config_config.pb
$configtxlator_path compute_update --channel_id $channel --original syschannel_config_config_original.pb --updated syschannel_config_config.pb --output syschannel_config_update.pb
$configtxlator_path proto_decode --input syschannel_config_update.pb --type common.ConfigUpdate | jq . > syschannel_config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$channel'", "type":2}},"data":{"config_update":'$(cat syschannel_config_update.json)'}}}' | jq . > syschannel_config_update_in_envelope.json
$configtxlator_path proto_encode --input syschannel_config_update_in_envelope.json --type common.Envelope --output syschannel_config_update_in_envelope.pb
cd ../../../../../../../
set=true
val=1
var=1
while [ $set ];
do
    $peer_bin_path channel update -f $network_path/config/channel-artifacts/application_channel/syschannel_config_update_in_envelope.pb -c $channel -o $component$number.$org_name.$domain:$port --tls true --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.$org_name.$domain.crt
    var=$(echo "$?")
    if [[ $val -eq 3  || $var -eq 0 ]] 
    then
        break
    fi
    sleep 10
    val=$((val+1))
done
if [[ $var -ne 0 ]] 
then
    exit
fi
echo "$channel updated using $component$number"
rm -rf $network_path/config/channel-artifacts/application_channel
}

addSystemTls() {
org_name=$p
component=$comp
number=$number
absolute_value $number
echo $element
domain=$1
channel=system-channel
network_path=etc/zeeve/fabric/$2
TLS_FILE=../../crypto-config/$org_name/new_certs/$component-$number$org_name/tls/server.crt
peer_bin_path=/usr/bin/peer
configtxlator_path=/usr/bin/configtxlator
export port=443
export CORE_PEER_TLS_CERT_FILE=$network_path/config/crypto-config/$org_name/$component-$number$org_name/tls/server.crt
export CORE_PEER_TLS_KEY_FILE=$network_path/config/crypto-config/$org_name/$component-$number$org_name/tls/server.key
export CORE_PEER_TLS_ROOTCERT_FILE=$network_path/config/crypto-config/TlsCaCerts/tlsca.$org_name.$domain.crt
export CORE_PEER_MSPCONFIGPATH=$network_path/config/crypto-config/$org_name/Admin-$org_name
export CORE_PEER_LOCALMSPID=${org_name}MSP
export CORE_PEER_ADDRESS=$component$number.$org_name.$domain:$port
export CORE_PEER_TLS_ENABLED=true
mkdir $network_path/config/channel-artifacts/system_channel
set=true
val=1
var=1
while [ $set ];
do
    $peer_bin_path channel fetch config $network_path/config/channel-artifacts/system_channel/config_block.pb -o $component$number.$org_name.$domain:$port -c $channel --tls --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.$org_name.$domain.crt
    var=$(echo "$?")
    if [[ $val -eq 3  || $var -eq 0 ]] 
    then
        break
    fi
    sleep 10
    val=$((val+1))
done 
if [[ $var -ne 0 ]] 
then
    exit
fi
echo "$channel fetched using $component$number"
cd $network_path/config/channel-artifacts/system_channel
$configtxlator_path proto_decode --input config_block.pb --type common.Block --output syschannel_config.json 
cat syschannel_config.json | jq .data.data[0].payload.data.config > syschannel_config_config.json
cat syschannel_config.json | jq .data.data[0].payload.data.config > syschannel_config_config_original.json
tls_cert=$(base64 --wrap=0 $TLS_FILE)
jq --arg cert "${tls_cert}" --argjson element "$element" '.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters[$element].client_tls_cert = $cert' syschannel_config_config.json > temp.json && cp temp.json syschannel_config_config.json
jq --arg cert "${tls_cert}" --argjson element "$element" '.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters[$element].server_tls_cert = $cert' syschannel_config_config.json > temp.json && cp temp.json syschannel_config_config.json
$configtxlator_path proto_encode --input syschannel_config_config_original.json --type common.Config --output syschannel_config_config_original.pb
$configtxlator_path proto_encode --input syschannel_config_config.json --type common.Config --output syschannel_config_config.pb
$configtxlator_path compute_update --channel_id $channel --original syschannel_config_config_original.pb --updated syschannel_config_config.pb --output syschannel_config_update.pb
$configtxlator_path proto_decode --input syschannel_config_update.pb --type common.ConfigUpdate | jq . > syschannel_config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$channel'", "type":2}},"data":{"config_update":'$(cat syschannel_config_update.json)'}}}' | jq . > syschannel_config_update_in_envelope.json
$configtxlator_path proto_encode --input syschannel_config_update_in_envelope.json --type common.Envelope --output syschannel_config_update_in_envelope.pb
cd ../../../../../../../
set=true
val=1
var=1
while [ $set ];
do
    $peer_bin_path channel update -f $network_path/config/channel-artifacts/system_channel/syschannel_config_update_in_envelope.pb -c $channel -o $component$number.$org_name.$domain:$port --tls true --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.$org_name.$domain.crt
    var=$(echo "$?")
    if [[ $val -eq 3  || $var -eq 0 ]] 
    then
        break
    fi
    sleep 10
    val=$((val+1))
done
if [[ $var -ne 0 ]] 
then
    exit
fi
echo "$channel updated using $component$number"
if [[ $number -eq 1 ]]
then
    echo $number
    org_num=$number
    number=2
    export port=443
    set=true
    val=1
    var=1
    while [ $set ];
    do
        $peer_bin_path channel fetch config $network_path/config/channel-artifacts/system_channel/latest_config.block -o $component$number.$org_name.$domain:$port -c $channel --tls --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.$org_name.$domain.crt 
        var=$(echo "$?")
        if [[ $val -eq 3  || $var -eq 0 ]] 
        then
            break
        fi
        sleep 10
        val=$((val+1))
    done  
    if [[ $var -ne 0 ]] 
    then
        exit
    fi
    echo "$channel fetched using $component$number"
    number=$org_num
    kubectl delete secret zeeve-genesis-$component$number-$org_name -n blockchain-$org_name
    kubectl create secret generic zeeve-genesis-$component$number-$org_name -n blockchain-$org_name --from-file=genesis.block=${network_path}/config/channel-artifacts/system_channel/latest_config.block   
else
    echo $number
    org_num=$number
    number=1
    export port=443
    set=true
    val=1
    var=1
    while [ $set ];
    do
        $peer_bin_path channel fetch config $network_path/config/channel-artifacts/system_channel/latest_config.block -o $component$number.$org_name.$domain:$port -c $channel --tls --cafile $network_path/config/crypto-config/TlsCaCerts/tlsca.$org_name.$domain.crt 
        var=$(echo "$?")
        if [[ $val -eq 3  || $var -eq 0 ]] 
        then
            break
        fi
        sleep 10
        val=$((val+1))
    done 
    if [[ $var -ne 0 ]] 
    then
        exit
    fi
    echo "$channel fetched using $component$number"
    number=$org_num
    kubectl delete secret zeeve-genesis-$component$number-$org_name -n blockchain-$org_name
    kubectl create secret generic zeeve-genesis-$component$number-$org_name -n blockchain-$org_name --from-file=genesis.block=${network_path}/config/channel-artifacts/system_channel/latest_config.block
fi
kubectl scale deployment/$component-$number$org_name-hlf-ord -n blockchain-$org_name --replicas=0
sleep 10
kubectl scale deployment/$component-$number$org_name-hlf-ord -n blockchain-$org_name --replicas=1
rm -rf $network_path/config/channel-artifacts/system_channel
}

rotate_admin_certs() {
network_path=etc/zeeve/fabric/$2
org_name=$p
domain=$1
export tlsca_ingress=$(kubectl get ingress -n cas -l "app=hlf-ca,release=tlsca-$org_name" -o jsonpath="{.items[0].spec.rules[0].host}")
export ca_ingress=$(kubectl get ingress -n cas -l "app=hlf-ca,release=ca-$org_name" -o jsonpath="{.items[0].spec.rules[0].host}")
mkdir $network_path/config/crypto-config/TlsCaCerts/new_certs
mkdir ${network_path}/config/crypto-config/${org_name}/new_certs
export POD_NAME=$(kubectl get pods --namespace cas -l "app=hlf-ca,release=ca-$org_name" -o jsonpath="{.items[0].metadata.name}")
# kubectl exec -it $POD_NAME -n cas -- fabric-ca-client enroll -u https://${caadmin}:${caadminpw}@0.0.0.0:7054 --tls.certfiles /etc/hyperledger/fabric-ca/${ca_ingress}-cert.pem
kubectl cp cas/$POD_NAME:etc/hyperledger/fabric-ca/${ca_ingress}-cert.pem $network_path/config/crypto-config/TlsCaCerts/new_certs/${ca_ingress}.crt
FABRIC_CA_CLIENT_HOME=$network_path/config fabric-ca-client enroll -u https://Ufae0uiM:Iejaek0a@${ca_ingress} -M crypto-config/${org_name}/new_certs/admin_msp --tls.certfiles crypto-config/TlsCaCerts/new_certs/${ca_ingress}.crt --csr.hosts $domain
export POD_NAME=$(kubectl get pods --namespace cas -l "app=hlf-ca,release=tlsca-$org_name" -o jsonpath="{.items[0].metadata.name}")
# kubectl exec -it $POD_NAME -n cas -- fabric-ca-client enroll -u https://${tlsadmin}:${tlsadminpw}@0.0.0.0:7054 --tls.certfiles /etc/hyperledger/fabric-ca/${tlsca_ingress}-cert.pem
kubectl cp cas/$POD_NAME:etc/hyperledger/fabric-ca/${tlsca_ingress}-cert.pem $network_path/config/crypto-config/TlsCaCerts/new_certs/${tlsca_ingress}.crt
FABRIC_CA_CLIENT_HOME=$network_path/config fabric-ca-client enroll -u https://Ufae0uiM:Iejaek0a@${tlsca_ingress} -M crypto-config/${org_name}/new_certs/admin_tls --tls.certfiles crypto-config/TlsCaCerts/new_certs/${tlsca_ingress}.crt --enrollment.profile tls --csr.hosts  $domain
dir_path=${network_path}/config/crypto-config/${org_name}/new_certs
mkdir ${dir_path}/msp ${dir_path}/ca ${dir_path}/tlsca 
mkdir ${dir_path}/msp/admincerts ${dir_path}/msp/cacerts ${dir_path}/msp/tlscacerts
cp ${dir_path}/admin_msp/cacerts/*.pem ${dir_path}/ca/${ca_ingress}-cert.pem
cp ${dir_path}/admin_tls/tlscacerts/*.pem ${dir_path}/tlsca/${tlsca_ingress}-cert.pem
cp ${dir_path}/ca/${ca_ingress}-cert.pem ${dir_path}/msp/cacerts/
cp ${dir_path}/tlsca/${tlsca_ingress}-cert.pem ${dir_path}/msp/tlscacerts/
cp $network_path/config/crypto-config/$org_name/Admin-$org_name/config.yaml ${network_path}/config/crypto-config/$org_name/new_certs/msp/config.yaml
cp -r ${dir_path}/msp ${dir_path}/Admin-${org_name}
cp -r ${dir_path}/admin_msp/signcerts ${dir_path}/Admin-${org_name}/signcerts
mv ${dir_path}/Admin-${org_name}/signcerts/*.pem ${dir_path}/Admin-${org_name}/signcerts/Admin@${org_name}.${domain}-cert.pem
cp -r ${dir_path}/admin_msp/keystore ${dir_path}/Admin-${org_name}/keystore
cp ${dir_path}/Admin-${org_name}/signcerts/Admin@${org_name}.${domain}-cert.pem ${dir_path}/msp/admincerts/
rm -r ${dir_path}/admin_msp ${dir_path}/admin_tls
}

org_secrets() {
network_path=etc/zeeve/fabric/$1
org_name=$p
kubectl delete secret hlf--org-${org_name}-cacert -n blockchain-${org_name}
kubectl delete secret hlf--org-${org_name}-config -n blockchain-${org_name}
kubectl delete secret hlf--org-${org_name}-tlscacert -n blockchain-${org_name}
CA_CERT=$(ls $network_path/config/crypto-config/${org_name}/new_certs/msp/cacerts/*.pem)
kubectl create secret generic -n blockchain-${org_name} hlf--org-${org_name}-cacert --from-file=ca.${org_name}.${domain}-cert.pem=$CA_CERT
TLS_CA_CERT=$(ls $network_path/config/crypto-config/${org_name}/new_certs/msp/tlscacerts/*.pem)
kubectl create secret generic -n blockchain-${org_name} hlf--org-${org_name}-tlscacert --from-file=tlsca.${org_name}.${domain}-cert.pem=$TLS_CA_CERT
CONFIG_FILE=$(ls $network_path/config/crypto-config/$org_name/new_certs/msp/config.yaml)
kubectl create secret generic -n blockchain-${org_name} hlf--org-${org_name}-config --from-file=config.yaml=$CONFIG_FILE
}

component_secrets() {
network_path=etc/zeeve/fabric/$1
org_name=$p
component=$comp
number=$number
organization_name=$p
kubectl delete secret hlf--${component}-${number}${org_name}-idcert -n blockchain-${org_name}
kubectl delete secret hlf--${component}-${number}${org_name}-idkey -n blockchain-${org_name}
kubectl delete secret hlf--${component}-${number}${org_name}-tls  -n blockchain-${org_name}
msp_path=${network_path}/config/crypto-config/${organization_name}/new_certs/${component}-${number}${organization_name}/msp
tls_path=${network_path}/config/crypto-config/${organization_name}/new_certs/${component}-${number}${organization_name}/tls
TLS_CERT=$(ls ${tls_path}/server.crt)
TLS_KEY=$(ls ${tls_path}/server.key)
kubectl create secret generic -n blockchain-${organization_name} hlf--${component}-${number}${organization_name}-tls --from-file=server.crt=${TLS_CERT} --from-file=server.key=${TLS_KEY}
NODE_CERT=$(ls ${msp_path}/signcerts/*.pem)
NODE_KEY=$(ls ${msp_path}/keystore/*_sk)
kubectl create secret generic -n blockchain-${organization_name} hlf--${component}-${number}${organization_name}-idcert --from-file=${component}${number}.${organization_name}.${domain}-cert.pem=${NODE_CERT}
kubectl create secret generic -n blockchain-${organization_name} hlf--${component}-${number}${organization_name}-idkey --from-file=${NODE_KEY}
}

update_TlsCaCerts() {
network_path=etc/zeeve/fabric/$1
cp -r  $network_path/config/crypto-config/TlsCaCerts/new_certs  $network_path/config/crypto-config/new_certs
rm -rf $network_path/config/crypto-config/TlsCaCerts
mkdir $network_path/config/crypto-config/TlsCaCerts
cp -r  $network_path/config/crypto-config/new_certs/*  $network_path/config/crypto-config/TlsCaCerts
rm -rf $network_path/config/crypto-config/new_certs
}

update_crypto() {
network_path=etc/zeeve/fabric/$1
org_name=$p
echo $org_name
mkdir $network_path/config/crypto-config/new_certs
cp -r $network_path/config/crypto-config/$org_name/new_certs/* $network_path/config/crypto-config/new_certs
rm -rf $network_path/config/crypto-config/$org_name
mkdir $network_path/config/crypto-config/$org_name
cp -r $network_path/config/crypto-config/new_certs/* $network_path/config/crypto-config/$org_name
rm -rf $network_path/config/crypto-config/new_certs
}

component_rotate_certs() {
network_path=etc/zeeve/fabric/$2
org_name=$p
domain=$1
organization_name=$p
component=$comp
number=$number
export tlsca_ingress=$(kubectl get ingress -n cas -l "app=hlf-ca,release=tlsca-$org_name" -o jsonpath="{.items[0].spec.rules[0].host}")
export ca_ingress=$(kubectl get ingress -n cas -l "app=hlf-ca,release=ca-$org_name" -o jsonpath="{.items[0].spec.rules[0].host}")
mkdir $network_path/config/crypto-config/$org_name/new_certs/${component}-${number}${org_name}
mkdir $network_path/config/crypto-config/$org_name/new_certs/${component}-${number}${org_name}/msp $network_path/config/crypto-config/$org_name/new_certs/${component}-${number}${org_name}/tls
msp_path=${network_path}/config/crypto-config/${organization_name}/new_certs/${component}-${number}${organization_name}/msp
tls_path=${network_path}/config/crypto-config/${organization_name}/new_certs/${component}-${number}${organization_name}/tls
FABRIC_CA_HOME=${network_path}/config fabric-ca-client enroll -u https://${component}${number}:${component}${number}_pw@${tlsca_ingress} -M crypto-config/${org_name}/new_certs/${component}-${number}${organization_name}/tls --tls.certfiles crypto-config/TlsCaCerts/new_certs/${tlsca_ingress}.crt --enrollment.profile tls --csr.hosts $component$number.$org_name.$domain,localhost,0.0.0.0
mv ${tls_path}/tlscacerts/* ${tls_path}/ca.crt
mv ${tls_path}/signcerts/* ${tls_path}/server.crt
mv ${tls_path}/keystore/* ${tls_path}/server.key
rm -r ${tls_path}/cacerts ${tls_path}/keystore ${tls_path}/signcerts ${tls_path}/tlscacerts ${tls_path}/user
FABRIC_CA_HOME=${network_path}/config fabric-ca-client enroll -u https://${component}${number}:${component}${number}_pw@${ca_ingress} -M crypto-config/${org_name}/new_certs/${component}-${number}${organization_name}/msp --tls.certfiles crypto-config/TlsCaCerts/new_certs/${ca_ingress}.crt --csr.hosts $component$number.$org_name.$domain,localhost,0.0.0.0
cp $network_path/config/crypto-config/$org_name/Admin-$org_name/config.yaml ${msp_path}/config.yaml
mkdir ${msp_path}/tlscacerts
cp ${tls_path}/ca.crt ${msp_path}/tlscacerts/tlsca.${organization_name}.${domain}-cert.pem
mv ${msp_path}/cacerts/* ${msp_path}/cacerts/ca.${organization_name}.${domain}-cert.pem
mv ${msp_path}/signcerts/* ${msp_path}/signcerts/${component}${number}.${organization_name}.${domain}-cert.pem
}

kubectl get ns  --no-headers -o custom-columns=":metadata.name" >> ns.txt

filename='ns.txt'
SUB='blockchain'

while read p; 
do 
    STR=$p
    if [[ "$STR" == *"$SUB"* ]]; 
    then
        ORG=$(echo $STR | cut -d "-" -f2)
        echo $ORG >> orgs.txt
    fi
done < "$filename"

rm -rf ns.txt

filename='orgs.txt'

while read p; 
do 
    echo $p
    rotate_admin_certs $1 $2 
    org_secrets $2
done < "$filename"

while read p; 
do 
    helm list --short -n blockchain-$p >> components.txt
    file='components.txt'
    while read x; 
    do 
        STR=$x
        if [[ "$STR" == *"orderer"* ]]; 
        then
            component=$(echo $STR | cut -d "-" -f2)
            number=${component:0:1}
            echo $p
            echo $STR
            echo $number
            comp=orderer
            component_rotate_certs $1 $2
            component_secrets $2
            addApplicationTls $1 $2
            addSystemTls $1 $2
            sleep 200        
        elif [[ "$STR" == *"peer-"* ]]; 
        then
            component=$(echo $STR | cut -d "-" -f2)
            number=${component:0:1}
            echo $p
            echo $STR
            echo $number
            comp=peer
            component_rotate_certs $1 $2
            component_secrets $2
            kubectl scale deployment/$component-$number$p-hlf-peer -n blockchain-$p --replicas=0
            sleep 10
            kubectl scale deployment/$component-$number$p-hlf-peer -n blockchain-$p --replicas=1
            sleep 100
        fi
    done < "$file"
    update_crypto $2
done < "$filename"
update_TlsCaCerts $2
rm -rf orgs.txt components.txt