#!/bin/bash

#prereqs
network_path=etc/zeeve/fabric
org_name=$1
domain="minikube"
ca_ingress="ca.$org_name.$domain"
tlsca_ingress="tlsca.$org_name.$domain"
export PATH=etc/zeeve/fabric-samples/bin/:$PATH

# Create CA's for orgs

helm install ca-$org_name ./hlf-ca -f ./helm_values/${org_name}/ca.yaml -n cas
helm install tlsca-$org_name ./hlf-ca -f ./helm_values/${org_name}/tls-ca.yaml -n cas

sleep 100

export tlsca_port=$(kubectl get --namespace cas -o jsonpath="{.spec.ports[0].nodePort}" services tlsca-$org_name-hlf-ca)
export ca_port=$(kubectl get --namespace cas -o jsonpath="{.spec.ports[0].nodePort}" services ca-$org_name-hlf-ca)

# Generate crypto

export POD_NAME=$(kubectl get pods --namespace cas -l "app=hlf-ca,release=ca-$org_name" -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD_NAME -n cas -- fabric-ca-client enroll -u https://admin:adminpw@0.0.0.0:7054 --tls.certfiles /etc/hyperledger/fabric-ca/${ca_ingress}-cert.pem
kubectl exec -it -n cas $POD_NAME -- fabric-ca-client register --id.name Ufae0uiM --id.secret Iejaek0a --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" --tls.certfiles /etc/hyperledger/fabric-ca/${ca_ingress}-cert.pem
kubectl cp cas/$POD_NAME:etc/hyperledger/fabric-ca/${ca_ingress}-cert.pem $network_path/config/crypto-config/TlsCaCerts/${ca_ingress}.crt
FABRIC_CA_CLIENT_HOME=$network_path/config fabric-ca-client enroll -u https://Ufae0uiM:Iejaek0a@${ca_ingress}:$ca_port -M crypto-config/${org_name}/admin_msp --tls.certfiles crypto-config/TlsCaCerts/${ca_ingress}.crt

export POD_NAME=$(kubectl get pods --namespace cas -l "app=hlf-ca,release=tlsca-$org_name" -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it $POD_NAME -n cas -- fabric-ca-client enroll -u https://admin:adminpw@0.0.0.0:7054 --tls.certfiles /etc/hyperledger/fabric-ca/${tlsca_ingress}-cert.pem
kubectl exec -it  -n cas $POD_NAME -- fabric-ca-client register --id.name Ufae0uiM --id.secret Iejaek0a --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" --tls.certfiles /etc/hyperledger/fabric-ca/${tlsca_ingress}-cert.pem
kubectl cp cas/$POD_NAME:etc/hyperledger/fabric-ca/${tlsca_ingress}-cert.pem $network_path/config/crypto-config/TlsCaCerts/${tlsca_ingress}.crt
FABRIC_CA_CLIENT_HOME=$network_path/config fabric-ca-client enroll -u https://Ufae0uiM:Iejaek0a@${tlsca_ingress}:$tlsca_port -M crypto-config/${org_name}/admin_tls --tls.certfiles crypto-config/TlsCaCerts/${tlsca_ingress}.crt --enrollment.profile tls

#create msp folders
dir_path=${network_path}/config/crypto-config/${org_name}
mkdir ${dir_path}/msp ${dir_path}/ca ${dir_path}/tlsca 
mkdir ${dir_path}/msp/admincerts ${dir_path}/msp/cacerts ${dir_path}/msp/tlscacerts

cp ${dir_path}/admin_msp/cacerts/*.pem ${dir_path}/ca/${ca_ingress}-cert.pem
cp ${dir_path}/admin_tls/tlscacerts/*.pem ${dir_path}/tlsca/${tlsca_ingress}-cert.pem
cp ${dir_path}/ca/${ca_ingress}-cert.pem ${dir_path}/msp/cacerts/
cp ${dir_path}/tlsca/${tlsca_ingress}-cert.pem ${dir_path}/msp/tlscacerts/

cp ./config/config.yaml ${network_path}/config/crypto-config/$org_name/msp/config.yaml

cp -r ${dir_path}/msp ${dir_path}/Admin-${org_name}
cp -r ${dir_path}/admin_msp/signcerts ${dir_path}/Admin-${org_name}/signcerts
mv ${dir_path}/Admin-${org_name}/signcerts/*.pem ${dir_path}/Admin-${org_name}/signcerts/Admin@${org_name}.${domain}-cert.pem
cp -r ${dir_path}/admin_msp/keystore ${dir_path}/Admin-${org_name}/keystore
cp ${dir_path}/Admin-${org_name}/signcerts/Admin@${org_name}.${domain}-cert.pem ${dir_path}/msp/admincerts/

kubectl create namespace blockchain-${org_name}

CA_CERT=$(ls $network_path/config/crypto-config/${org_name}/msp/cacerts/*.pem)
kubectl create secret generic -n blockchain-${org_name} hlf--org-${org_name}-cacert --from-file=ca.${org_name}.${domain}-cert.pem=$CA_CERT
TLS_CA_CERT=$(ls $network_path/config/crypto-config/${org_name}/msp/tlscacerts/*.pem)
kubectl create secret generic -n blockchain-${org_name} hlf--org-${org_name}-tlscacert --from-file=tlsca.${org_name}.${domain}-cert.pem=$TLS_CA_CERT
CONFIG_FILE=$(ls $network_path/config/crypto-config/$org_name/msp/config.yaml)
kubectl create secret generic -n blockchain-${org_name} hlf--org-${org_name}-config --from-file=config.yaml=$CONFIG_FILE

rm -r ${dir_path}/admin_msp ${dir_path}/admin_tls
