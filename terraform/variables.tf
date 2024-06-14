variable "hcloud_token" {
    sensitive = true # Requires terraform >= 0.14
    type = string
}

variable "smtp_user" {
    type = string
}
variable "smtp_password" {
    sensitive = true # Requires terraform >= 0.14
    type = string
}

variable "smtp_host" {
    type = string
}

variable "encryption_password" {
    sensitive = true # Requires terraform >= 0.14
    type = string
}

variable "encryption_salt" {
    sensitive = true # Requires terraform >= 0.14
    type = string
}

variable "microos_x86_snapshot_id" {
    type = string
}

variable "microos_arm_snapshot_id" {
    type = string
}