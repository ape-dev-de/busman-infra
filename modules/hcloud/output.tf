output "master_ip" {
    value = hcloud_server.kubernetes-master.ipv4_address
}

output "root_private_key" {
    value = tls_private_key.root.private_key_openssh
    sensitive = true
}

output "root_public_key" {
    value = tls_private_key.root.public_key_openssh
}