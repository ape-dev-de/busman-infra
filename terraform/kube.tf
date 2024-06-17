# This is where you put your resource declaration
resource "tls_private_key" "terraform_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


module "kube-hetzner" {
  providers = {
    hcloud = hcloud
  }

  hcloud_token = var.hcloud_token

  source = "kube-hetzner/kube-hetzner/hcloud"

  ssh_port        = 2220
  ssh_public_key  = tls_private_key.terraform_key.public_key_openssh
  ssh_private_key = tls_private_key.terraform_key.private_key_openssh

  network_region = "eu-central"

  microos_x86_snapshot_id = var.microos_x86_snapshot_id
  microos_arm_snapshot_id = var.microos_arm_snapshot_id

  automatically_upgrade_os = false

  # https://medium.com/@mahdad.ghasemian/setting-up-a-highly-available-kubernetus-cluster-k3s-on-hetzner-cloud-with-terraform-7a409a7a8528
  control_plane_nodepools = [
    {
      name        = "control-plane",
      server_type = "cx22",
      location    = "fsn1",
      labels      = [],
      taints      = [],
      count       = 1
      labels      = [
        "run=application",
        "run=packages",
        "node.kubernetes.io/server-usage=storage",
        "node.longhorn.io/create-default-disk=true"
      ],
    }
  ]

  agent_nodepools = [
    {
      name        = "agent-1",
      server_type = "cx22",
      location    = "fsn1",
      labels      = [
        "run=application",
        "run=packages",
        "node.kubernetes.io/server-usage=storage",
        "node.longhorn.io/create-default-disk=true"
      ],
      taints = [],
      count  = 0,
    },
  ]

  dns_servers = [
    "1.1.1.1",
    "8.8.8.8",
    "2606:4700:4700::1111",
  ]

  create_kubeconfig = true
  export_values     = true

  extra_firewall_rules = [
    # {
    #   description     = "For Postgres"
    #   direction       = "in"
    #   protocol        = "tcp"
    #   port            = "5432"
    #   source_ips      = ["0.0.0.0/0", "::/0"]
    #   destination_ips = [] # Won't be used for this rule
    # },
    /*{
        description     = "To Allow ArgoCD access to resources via SSH"
        direction       = "out"
        protocol        = "tcp"
        port            = "22"
        source_ips      = [] # Won't be used for this rule
        destination_ips = ["0.0.0.0/0", "::/0"]
    }*/
  ]

  enable_longhorn        = true
  longhorn_replica_count = 2

  longhorn_values = <<EOT
defaultSettings:
    createDefaultDiskLabeledNodes: true
    defaultDataPath: /var/longhorn
    node-down-pod-deletion-policy: delete-both-statefulset-and-deployment-pod
persistence:
    defaultFsType: ext4
    defaultClassReplicaCount: 1
    defaultClass: true
    reclaimPolicy: Retain
    EOT
}

output "kubeconfig" {
  value     = module.kube-hetzner.kubeconfig
  sensitive = true
}