# Configure RKE provider
provider "rke" {
  log_file = "rke_debug.log"
}

# Create a new RKE cluster using arguments
resource rke_cluster "berrycluster" {
  depends_on = [null_resource.next]
  # rke may complain if the Docker version is newer than what Rancher has tested
  ignore_docker_version = true
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

  ## limited CNIs running on arm64
  network {
    plugin = "flannel"
  }

  ## default to arm64 versions that seem to work
  system_images {
    alpine                      = "rancher/rke-tools:v0.1.71"
    nginx_proxy                 = "rancher/rke-tools:v0.1.71"
    cert_downloader             = "rancher/rke-tools:v0.1.71"
    kubernetes_services_sidecar = "rancher/rke-tools:v0.1.71"
    nodelocal                   = "rancher/rke-tools:v0.1.71"
    ingress                     = "rancher/nginx-ingress-controller:nginx-0.35.0-rancher2"
    etcd                        = "rancher/coreos-etcd:v3.4.13-arm64"
  }

  upgrade_strategy {
    drain                  = true
    max_unavailable_worker = "20%"
  }
}