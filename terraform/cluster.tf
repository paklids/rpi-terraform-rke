# Configure RKE provider
provider "rke" {
  log_file = "rke_debug.log"
}

# Create a new RKE cluster using arguments
resource rke_cluster "berrycluster" {
  depends_on = [null_resource.next]
  #disable_port_check = true
  dynamic "nodes" {
    for_each = local.nodes
    content {
      address = nodes.value.ip_addr
      user    = local.user
      role    = nodes.value.role
      ssh_key = file("${path.module}/../${local.private_key}")
    }
  }

  upgrade_strategy {
    drain                  = true
    max_unavailable_worker = "20%"
  }
}