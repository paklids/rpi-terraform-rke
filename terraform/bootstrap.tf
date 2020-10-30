
resource "null_resource" "raspberry_pi_bootstrap" {
  # increment version here if you wish this to run again after running it the first time
  triggers = {
    version = "0.1.2"
  }
  for_each = local.nodes
  connection {
    type        = "ssh"
    user        = local.user
    private_key = file("${path.module}/../${local.private_key}")
    host        = each.value.ip_addr
  }

  # for use with Ubuntu 20.10 for RPi 3 or 4 (arm64 only)
  provisioner "file" {
    source      = "files/daemon.json"
    destination = "./daemon.json"
  }

  # for use with Ubuntu 20.10 for RPi 3 or 4 (arm64 only)
  provisioner "remote-exec" {
    inline = [
      # set hostname
      "sudo hostnamectl set-hostname ${each.value.hostname}",
      "if ! grep -qP ${each.value.hostname} /etc/hosts; then echo '127.0.1.1 ${each.value.hostname}' | sudo tee -a /etc/hosts; fi",

      # date time config (you use UTC...right?!?)
      "sudo timedatectl set-timezone UTC",
      "sudo timedatectl set-ntp true",

      # system & package updates - then lock kernel updates
      "sudo apt-get update -y",
      "sudo apt-get -o Dpkg::Options::='--force-confnew' upgrade -y",
      "sleep 5",
      "sudo apt-get -o Dpkg::Options::='--force-confnew' dist-upgrade -y",
      "sleep 5",
      "sudo apt --fix-broken install -y",
      "sudo apt-mark hold linux-raspi",

      # install docker for arm64 (only have focal version right now)
      "sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common ",
      "echo 'deb [arch=arm64] https://download.docker.com/linux/ubuntu focal stable' | sudo tee /etc/apt/sources.list.d/docker.list",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io",

      # replace the contents of /etc/docker/daemon.json to enable the systemd cgroup driver
      "sudo rm -f /etc/docker/daemon.json",
      "cat ~/daemon.json | sudo tee /etc/docker/daemon.json",
      "rm -f ~/daemon.json",
      "sudo systemctl enable --now docker",

      # check each kernel command line option and append if necessary
      "if ! grep -qP 'cgroup_enable=cpuset' /boot/firmware/cmdline.txt; then sudo sed -i.bck '$s/$/ cgroup_enable=cpuset/' /boot/firmware/cmdline.txt; fi",
      "if ! grep -qP 'cgroup_enable=memory' /boot/firmware/cmdline.txt; then sudo sed -i.bck '$s/$/ cgroup_enable=memory/' /boot/firmware/cmdline.txt; fi",
      "if ! grep -qP 'cgroup_memory=1' /boot/firmware/cmdline.txt; then sudo sed -i.bck '$s/$/ cgroup_memory=1/' /boot/firmware/cmdline.txt; fi",
      "if ! grep -qP 'swapaccount=1' /boot/firmware/cmdline.txt; then sudo sed -i.bck '$s/$/ swapaccount=1/' /boot/firmware/cmdline.txt; fi",

      # allow iptables to see bridged traffic
      "echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> ./k8s.conf",
      "echo 'net.bridge.bridge-nf-call-iptables = 1' >> ./k8s.conf",
      "cat ./k8s.conf | sudo tee /etc/sysctl.d/k8s.conf",
      "rm -f ./k8s.conf",
      "sudo sysctl --system",

      # # Add the packages.cloud.google.com apt key
      # "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",

      # # Add the Kubernetes repo (focal is not yet available so using xenial for now)
      # "echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list",

      # # Update the apt cache and install kubelet, kubeadm, and kubectl
      # "sudo apt update",
      # "sleep 3",
      # "sudo apt install -y kubelet kubeadm kubectl",
      # "sudo apt autoremove -y",

      # # Disable (mark as held) updates for the Kubernetes packages
      # "sudo apt-mark hold kubelet kubeadm kubectl",

      # reboot to confirm the changes are persistent
      "sudo shutdown -r +0"
    ]
  }
}

# wait 90 seconds after the node(s) have rebooted before doing anything else
resource "time_sleep" "wait_90_seconds" {
  depends_on      = [null_resource.raspberry_pi_bootstrap]
  create_duration = "90s"
}
resource "null_resource" "next" {
  depends_on = [time_sleep.wait_90_seconds]
}