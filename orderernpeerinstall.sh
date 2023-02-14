helm install orderer-1org1 ./hlf-ord -f ./helm_values/org1/orderer1.yaml -n blockchain-org1
helm install orderer-2org1 ./hlf-ord -f ./helm_values/org1/orderer2.yaml -n blockchain-org1
helm install orderer-3org1 ./hlf-ord -f ./helm_values/org1/orderer3.yaml -n blockchain-org1

helm install cdb-peer1 ./hlf-couchdb -f ./helm_values/org1/cdb.yaml -n blockchain-org1
kubectl get secret cdb-peer1-hlf-couchdb -n blockchain-org1 -o yaml  

kubectl -n blockchain-org1 exec ${couchdb_pod} -- curl -X PUT http://couchdb:<couchdb password>@127.0.0.1:5984/_users

helm install peer-1org1 ./hlf-peer -f ./helm_values/org1/peer1.yaml -n blockchain-org1 