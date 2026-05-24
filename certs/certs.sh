# Just for archive purposes
openssl genrsa -out ca.key 4096
openssl req -x509 -new -nodes -key ca.key -subj "/CN=etcd-ca" -days 7300 -out ca.crt
openssl genrsa -out etcd-postgres0.key 4096
openssl genrsa -out etcd-postgres1.key 4096
openssl genrsa -out etcd-postgres2.key 4096
openssl req -new -key etcd0.key -out etcd0.csr -config etcd0.cnf
openssl req -new -key etcd1.key -out etcd1.csr -config etcd1.cnf
openssl req -new -key etcd2.key -out etcd2.csr -config etcd2.cnf
openssl x509 -req -in etcd0.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out etcd0.crt -days 7300 -sha256 -extensions v3_req -extfile etcd0.cnf
openssl x509 -req -in etcd1.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out etcd1.crt -days 7300 -sha256 -extensions v3_req -extfile etcd1.cnf
openssl x509 -req -in etcd2.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out etcd2.crt -days 7300 -sha256 -extensions v3_req -extfile etcd2.cnf

