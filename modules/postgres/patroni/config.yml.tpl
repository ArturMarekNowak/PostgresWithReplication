scope: postgresql-cluster
namespace: /service/
name: postgres-${node_index}

etcd3:
  hosts: ${etcd_hosts}  # etcd cluster nodes
  protocol: https
  cacert: /etc/etcd/ssl/ca.crt
  cert: /etc/etcd/ssl/etcd.crt
  key: /etc/etcd/ssl/etcd.key

restapi:
  listen: 0.0.0.0:8008
  connect_address: ${node_ip}:8008
  certfile: /var/lib/postgresql/ssl/server.pem

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
        parameters:
            ssl: 'on'
            ssl_cert_file: /var/lib/postgresql/ssl/server.crt
            ssl_key_file: /var/lib/postgresql/ssl/server.key
        pg_hba:
        - hostssl replication replicator 127.0.0.1/32 md5
%{ for ip in node_ips ~}
        - hostssl replication replicator ${ip}/32 md5
%{ endfor ~}
        - hostssl all all 127.0.0.1/32 md5
        - hostssl all all 0.0.0.0/0 md5
  initdb:
    - encoding: UTF8
    - data-checksums

postgresql:
  listen: 0.0.0.0:5432
  connect_address: ${node_ip}:5432
  data_dir: /mnt/pgdata/data
  bin_dir: /usr/lib/postgresql/17/bin
  authentication:
    superuser:
      username: postgres
      password: ${superuser_password}
    replication:
      username: replicator
      password: ${replication_password}
  parameters:
    max_connections: 100
    shared_buffers: 256MB

tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
