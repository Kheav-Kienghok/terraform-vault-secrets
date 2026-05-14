variable "vault_address" {
  type        = string
  description = "Vault server URL"
}

variable "vault_token" {
  type        = string
  description = "Vault root token or Terraform token"
  sensitive   = true
}

variable "key_name" {
  type        = string
  description = "Name of the AWS EC2 key pair for SSH access"
  default     = ""
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}
