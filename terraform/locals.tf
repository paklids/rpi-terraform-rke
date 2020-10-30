
locals {
  # username that terraform will use to ssh to the node(s)
  user = "terraform"

  # the filename of the private key used to ssh to the node(s)
  private_key = "terraformuser"

  # the list of nodes that will be bootstrapped
  nodes = {
    node1 = {
      hostname = "pinode1"
      ip_addr  = "192.168.1.91"
      role     = ["controlplane", "worker", "etcd"]
    },
    node2 = {
      hostname = "pinode2"
      ip_addr  = "192.168.1.92"
      role     = ["worker", "etcd"]
    },
    node3 = {
      hostname = "pinode3"
      ip_addr  = "192.168.1.93"
      role     = ["worker", "etcd"]
    }
  }

}