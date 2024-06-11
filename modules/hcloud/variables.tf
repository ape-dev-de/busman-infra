# Declare the hcloud_token variable from .tfvars
variable "hcloud_token" {
    sensitive = true # Requires terraform >= 0.14
    type = string
}

variable "public_keys" {
    description = "public Keys with access to Master Node"
    type = list(string)
}