#!/bin/bash
network_path=etc/zeeve/fabric
org_name=$1
domain="minikube"
ca_ingress="ca.$org_name.$domain"
tlsca_ingress="tlsca.$org_name.$domain"
organization_name=$1
component=$2
number=$3
export PATH=etc/zeeve/fabric-samples/bin/:$PATH

export tlsca_port=$(kubectl get --namespace cas -o jsonpath="{.spec.ports[0].nodePort}" services tlsca-$org_name-hlf-ca)
export ca_port=$(kubectl get --namespace cas -o jsonpath="{.spec.ports[0].nodePort}" services ca-$org_name-hlf-ca)


mkdir $network_path/config/crypto-config/$org_name/${component}-${number}${org_name}
mkdir $network_path/config/crypto-config/$org_name/${component}-${number}${org_name}/msp $network_path/config/crypto-config/$org_name/${component}-${number}${org_name}/tls

msp_path=${network_path}/config/crypto-config/${organization_name}/${component}-${number}${organization_name}/msp
tls_path=${network_path}/config/crypto-config/${organization_name}/${component}-${number}${organization_name}/tls

export ca_pod=$(kubectl get pods --namespace cas -l "app=hlf-ca,release=ca-$org_name" -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n cas $ca_pod -- fabric-ca-client register --id.name=${component}${number} --id.secret ${component}${number}_pw --id.type ${component} --tls.certfiles /etc/hyperledger/fabric-ca/${ca_ingress}-cert.pem

export tlsca_pod=$(kubectl get pods --namespace cas -l "app=hlf-ca,release=tlsca-$org_name" -o jsonpath="{.items[0].metadata.name}")
kubectl exec -n cas $tlsca_pod -- fabric-ca-client register --id.name=${component}${number} --id.secret ${component}${number}_pw --id.type ${component} --tls.certfiles /etc/hyperledger/fabric-ca/${tlsca_ingress}-cert.pem

FABRIC_CA_HOME=${network_path}/config fabric-ca-client enroll -u https://${component}${number}:${component}${number}_pw@${tlsca_ingress}:$tlsca_port -M crypto-config/${org_name}/${component}-${number}${organization_name}/tls --tls.certfiles crypto-config/TlsCaCerts/${tlsca_ingress}.crt --csr.hosts $domain --enrollment.profile tls

mv ${tls_path}/tlscacerts/* ${tls_path}/ca.crt
mv ${tls_path}/signcerts/* ${tls_path}/server.crt
mv ${tls_path}/keystore/* ${tls_path}/server.key
rm -r ${tls_path}/cacerts ${tls_path}/keystore ${tls_path}/signcerts ${tls_path}/tlscacerts ${tls_path}/user

TLS_CERT=$(ls ${tls_path}/server.crt)
TLS_KEY=$(ls ${tls_path}/server.key)
kubectl create secret generic -n blockchain-${organization_name} hlf--${component}-${number}${organization_name}-tls --from-file=server.crt=${TLS_CERT} --from-file=server.key=${TLS_KEY}

FABRIC_CA_HOME=${network_path}/config fabric-ca-client enroll -u https://${component}${number}:${component}${number}_pw@${ca_ingress}:$ca_port -M crypto-config/${org_name}/${component}-${number}${organization_name}/msp --tls.certfiles crypto-config/TlsCaCerts/${ca_ingress}.crt --csr.hosts $domain
cp ./config/config.yaml ${msp_path}/config.yaml
mkdir ${msp_path}/tlscacerts
cp ${tls_path}/ca.crt ${msp_path}/tlscacerts/tlsca.${organization_name}.${domain}-cert.pem
mv ${msp_path}/cacerts/* ${msp_path}/cacerts/ca.${organization_name}.${domain}-cert.pem
mv ${msp_path}/signcerts/* ${msp_path}/signcerts/${component}${number}.${organization_name}.${domain}-cert.pem
NODE_CERT=$(ls ${msp_path}/signcerts/*.pem)
NODE_KEY=$(ls ${msp_path}/keystore/*_sk)
kubectl create secret generic -n blockchain-${organization_name} hlf--${component}-${number}${organization_name}-idcert --from-file=${component}${number}.${organization_name}.${domain_suffix}-cert.pem=${NODE_CERT}
kubectl create secret generic -n blockchain-${organization_name} hlf--${component}-${number}${organization_name}-idkey --from-file=${NODE_KEY}