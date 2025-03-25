disable_mlock = true
ui = true
listener "tcp" {
   address            = "0.0.0.0:8200"
   cluster_address    = "0.0.0.0:8201"
   tls_cert_file      = "/vault/tls/cert.pem"
   tls_key_file       = "/vault/tls/key.pem"   
   tls_client_ca_file = "/vault/tls/ca.pem"
   tls_disable        =  0
}

storage "raft" {
  path = "/vault/data"
  node_id = "raft_node"
}
cluster_addr = "http://127.0.0.1:8201"
api_addr         = "http://0.0.0.0:8200"
max_lease_ttl         = "10h"
default_lease_ttl    = "10h"
raw_storage_endpoint     = true
