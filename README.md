# rpi-terraform-rke

Setup a Raspberry Pi Kubernetes cluster with Terraform

See examples for setting up distributed storage using Kadalu, using Helm charts to run Minecraft and publish your dynamic dns.

## What does this do?

This takes a Raspberry Pi (arm64 - so It will need to be a 3b or 4b) and sets these up in
a cluster using Rancher Lab's `rke` Terraform provider.

There is a small amount of config to be done to each node and then everything can be configured
remotely via Terraform (see below)

Just a note: I would have loved to try Ubuntu Core 20 as the host OS but it simply does not support the cloud-init functionality that I need (yet).

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

7. At this point you should see the system-boot partition mounted (or remove the microSD card and
   reinsert it to your machine).

You will need to edit at least 2 files.

Edit `network-config` similar to this (like updating the IP address):

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

Edit `user-data` and paste in the SSH public key that you created earlier (should be in `terraformuser.pub`)

```
#cloud-config
# vim: syntax=yaml
#
growpart: { mode: "off" }
locale: en_US.UTF-8
resize_rootfs: false
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
      - ssh-rsa AAAAB...== terraform

# expand the root partition up to a certain location on the disk
# note that the value is the marker on the disk where the root partion will end
# and can be in MB, GB or % of overall disk (see parted units)
# note that the root partition is where container images are stored
#
# create an additional partition and mark where on the disk it starts and stops
# this can be used later for a cluster filesystem
runcmd:
  - [partprobe]
  - 'echo "Yes\n16000MB" | sudo parted /dev/mmcblk0 ---pretend-input-tty resizepart 2'
  - [resize2fs, /dev/mmcblk0p2]
  - [partprobe]
  - [parted, /dev/mmcblk0, mkpart, primary, xfs, 16001MB, 100%]
  - [mkfs.xfs, -f, /dev/mmcblk0p3]
  - [partprobe]
```

You may edit the partition values as needed. Once complete with those edits, you may unmount `system-boot`
, move the SD card into its respective Pi and boot.

If Etcher is not your jam then I've included a script `write_sd.sh` to automate some of the manual steps. Read it, tweak it, improve it.

8. Test that you can now ssh into your freshly built Pi

`ssh -i ./terraformuser terraform@192.168.1.91`

This will SSH to the IP address (where your Pi should now be located) using the `./terraformuser` SSH private key
that you have stored locally. It will login as the `terraform` user, which should now be the default user on the Pi.

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

4. Take the output from terraform and set that to your default kube config

`tee ~/.kube/config <<<"$(terraform output kube_config_yaml)"`

OR

Take the output from Terraform to build your `kube_config_cluster.yml` file used by kubectl

`terraform output kube_config_yaml > kube_config_cluster.yml`

5. Test that the cluster is running successfully (add kubeconfig flag if you're using that `--kubeconfig kube_config_cluster.yml` )

`kubectl version`

`kubectl get nodes`

And there you go - a kubernetes cluster running on Raspberry Pi(s) !

## What about distributed storage?

If you followed these directions then you should have a partition on each node that can be used for distributed storage.

See the `examples` directory where you may find the README and files to setup Kadalu, MetalLB and Minecraft.
