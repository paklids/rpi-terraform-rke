
locals {
  # username that terraform will use to ssh to the node(s)
  user = "terraform"

  # the filename of the private key used to ssh to the node(s)
  private_key = "terraformuser"

  # the list of nodes that will be bootstrapped
  nodes = {
    node1 = {
      hostname = "kibble1"
      ip_addr  = "192.168.1.61"
      role     = ["controlplane", "worker", "etcd"]
    },
    node2 = {
      hostname = "kibble2"
      ip_addr  = "192.168.1.62"
      role     = ["worker", "etcd"]
    },
    node3 = {
      hostname = "kibble3"
      ip_addr  = "192.168.1.63"
      role     = ["worker", "etcd"]
    }
  }

}