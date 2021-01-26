# rpi-terraform-rke

Setup a Raspberry Pi Kubernetes cluster with Terraform

## What does this do?

This takes a Raspberry Pi (arm64 - so It will need to be a 3b or 4b) and sets these up in
a cluster using Rancher Lab's `rke` Terraform provider.

There is a small amount of config to be done to each node and then everything can be configured
remotely via Terraform (see below)

## Where do I start?

1. Buy a:

   - Raspberry Pi (or 3 of them)
   - a new microSD card for each Pi
   - a case for each Pi (a fan preferred)
   - a small gigabit switch to network these together

2. Choose a set of static IP addresses that you will use for each Pi on your network

3. In the root of this project create an ssh key that will be used to connect to each Pi

`ssh-keygen -t rsa -b 4096 -C "terraformuser" -f ./terraformuser`

4. Download 64bit Ubuntu server image here https://ubuntu.com/download/raspberry-pi ( 20.10 tested)

5. Write the image to the microSD card using a tool like Etcher or dd.

6. Pull down this repo using `git clone git@github.com:paklids/rpi-terraform-rke.git`

7. Remove the microSD card and reinsert it to your machine.

You will need to put in the static IP address for each respective Pi and paste in the ssh public key
that you created earlier.

Edit these files to match:

file: `network-config` (edit IP address)

```
version: 2
ethernets:
  eth0:
    # Rename the built-in ethernet device to "eth0"
    match:
      driver: bcmgenet smsc95xx lan78xx
    set-name: eth0
    optional: true
    dhcp4: no
    addresses: [192.168.1.91/24]
    gateway4: 192.168.1.1
    nameservers:
      addresses: [192.168.1.1,8.8.8.8]
```

file: `user-data` (paste in ssh public key)

```
#cloud-config
# vim: syntax=yaml
#
ssh_pwauth: false
system_info:
  default_user:
    name: terraform
users:
  - default
  - name: terraform
    gecos: Terrafom User
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, adm, docker
    ssh_import_id: None
    lock_passwd: true
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1... terraform
```

More to come on customizing the partition layout on the SD card

8. Test that you can now ssh into your freshly built Pi

`ssh -i ./terraformuser terraform@192.168.1.91`

Now you are almost ready to run Terraform!

## What more do I need?

1. If you used a different username for setup - edit that in the `terraform/locals.tf`

2. Edit your `terraform/locals.tf` file to match each Pi and what you want it to perform
   within the cluster

3. From within the terraform directory and using Terraform v0.13 - run:

`terraform fmt -recursive`

`terraform init`

and then

`terraform plan`

If it looks good then run `terraform apply`

This will bootstrap the Pi nodes, reboot them and then provision the cluster using `rke`

4. Take the output from Terraform to build your `kube_config_cluster.yml` file used by kubectl

`terraform output kube_config_yaml > kube_config_cluster.yml`

5. Test that the cluster is running successfully

`kubectl --kubeconfig kube_config_cluster.yml version`

`kubectl --kubeconfig kube_config_cluster.yml get nodes`

And there you go - a kubernetes cluster running on Raspberry Pi(s) !
