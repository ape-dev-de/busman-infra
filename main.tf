terraform {
    required_providers {
        hcloud = {
            source  = "hetznercloud/hcloud"
            # Here we use version 1.45.0, this may change in the future
            version = "1.45.0"
        }
    }
}

# Configure the Hetzner Cloud Provider with your token
provider "hcloud" {
    token = var.hcloud_token
}

resource "tls_private_key" "worker_key" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

resource "tls_private_key" "terraform_key" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

module "hcloud" {
    source = "./modules/hcloud"

    hcloud_token = "${var.hcloud_token}"
    public_keys = [
        tls_private_key.worker_key.public_key_openssh,
        tls_private_key.terraform_key.public_key_openssh
    ]
}

locals {
    kube_config_path = "${path.module}/.kube/config"
    k8s_host = "https://${module.hcloud.master_ip}:6443"
}

resource "local_sensitive_file" "master_root_private_key" {
    filename = "./root.id-rsa"
    content = module.hcloud.root_private_key
}

resource "local_file" "kube_config_file" {
    content = ""
    filename = pathexpand(local.kube_config_path)
    file_permission = 0700 
    
    provisioner "local-exec" {
        # wait until k3s is installed and ready 
        command = "until curl -k ${local.k8s_host}; do sleep 5; done;"
    }
    
    provisioner "local-exec" {
        command="ssh -i ${pathexpand(local_sensitive_file.master_root_private_key.filename)} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@${ module.hcloud.master_ip} \"cat /etc/rancher/k3s/k3s.yaml | sed -e 's/127.0.0.1/${module.hcloud.master_ip}/g' \" > ${pathexpand(local.kube_config_path)}"
    }
}

variable "namespace" {
    type    = string
    default = "appsmith-ce"
}


locals {
  kube_config = yamldecode(file(local_file.kube_config_file.filename))
}

provider "kubernetes" {
    host = local.k8s_host
    
    config_path = "./.kube/config"
    
    cluster_ca_certificate = base64decode(local.kube_config.clusters[0].cluster.certificate-authority-data)
}

resource "kubernetes_namespace" "appsmith-ce" {
    metadata {
        name = var.namespace
    }
    
    depends_on = [ local_file.kube_config_file ]
}

resource "kubernetes_namespace" "ingress" {
    metadata {
        name = "ingress"
    }
}

resource "kubernetes_namespace" "cockroach" {
    metadata {
        name = "cockroach"
    }
}


provider "helm" {
    # Several Kubernetes authentication methods are possible: https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs#authentication
    kubernetes {
        host = local.k8s_host
        
        config_path = local_file.kube_config_file.filename
        cluster_ca_certificate = base64decode(local.kube_config.clusters[0].cluster.certificate-authority-data)
    }
}

resource "helm_release" "ingress-nginx" {
    chart = "ingress-nginx"
    name = "ingress-nginx"
    
    namespace = "ingress"
    repository= "https://kubernetes.github.io/ingress-nginx"
}

resource "helm_release" "appsmith" {
    chart = "appsmith"
    name = "appsmith"

    namespace = var.namespace
    repository = "https://helm.appsmith.com"
    values = [
        "${templatefile("./apps/appsmith/values.yaml", {
            smtp_user = var.smtp_user,
            smtp_password = var.smtp_password,
            smtp_host = var.smtp_host,
            encryption_password = var.encryption_password,
            encryption_salt = var.encryption_salt
        })}"
    ]
    
    depends_on = [ kubernetes_namespace.appsmith-ce ]
}

resource "helm_release" "cockroach" {
    chart = "cockroachdb"
    name = "cockroachdb"

    namespace = "cockroach"
    repository = "https://charts.cockroachdb.com/"
}
