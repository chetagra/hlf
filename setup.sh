#!/bin/bash

mkdir etc
mkdir etc/zeeve
mkdir etc/zeeve/fabric

network_path=etc/zeeve/fabric

cp -r ../../fabric-samples ./etc/zeeve/fabric-samples

mkdir $network_path/config
mkdir $network_path/config/crypto-config
mkdir $network_path/config/crypto-config/TlsCaCerts
kubectl create ns cas