module "backend" {
    source = "./modules/backend"
}

locals {
    kube_config_path = "${path.module}/k3s_kubeconfig.yaml"
}

variable "namespace" {
    type    = string
    default = "appsmith"
}

provider "kubernetes" {
    config_path = local.kube_config_path
}

/*
resource "kubernetes_namespace" "appsmith-ce" {
    metadata {
        name = var.namespace
    }
}


resource "kubernetes_namespace" "cockroach" {
    metadata {
        name = "cockroach"
    }
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
*/