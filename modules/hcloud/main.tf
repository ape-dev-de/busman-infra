terraform {
    required_providers {
        hcloud = {
            source  = "hetznercloud/hcloud"
            # Here we use version 1.45.0, this may change in the future
            version = "1.45.0"
        }
    }
}

resource "hcloud_network" "private_network" {
    name     = "kubernetes-cluster"
    ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "private_network_subnet" {
    type         = "cloud"
    network_id   = hcloud_network.private_network.id
    network_zone = "eu-central"
    ip_range     = "10.0.1.0/24"
}

locals {
    cloud_init =  templatefile("${path.module}/templates/cloud-init.yml", {
        public_keys = var.public_keys
    })
}

resource "tls_private_key" "root" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

resource "hcloud_ssh_key" "root_ssh_key" {
    name = "root"
    public_key = tls_private_key.root.public_key_openssh
}

resource "hcloud_server" "kubernetes-master" {
    name        = "kubernetes-master"
    image       = "ubuntu-22.04"
    server_type = "cx22"
    location    = "fsn1"
    ssh_keys = [hcloud_ssh_key.root_ssh_key.name]

    public_net {
        ipv4_enabled = true
        ipv6_enabled = true
    }
    network {
        network_id = hcloud_network.private_network.id
        # IP Used by the master node, needs to be static
        # Here the worker nodes will use 10.0.1.1 to communicate with the master node
        ip         = "10.0.1.1"
    }
    user_data = local.cloud_init

    # If we don't specify this, Terraform will create the resources in parallel
    # We want this node to be created after the private network is created
    depends_on = [hcloud_network_subnet.private_network_subnet]
    
    lifecycle {
        ignore_changes = [ ssh_keys ]
        prevent_destroy = true
    }
}
