variable "aws_region" {
  type    = string
  default = "ap-southeast-1"
}

variable "key_name" {
  type        = string
  description = "Name of your EC2 key pair (create one in AWS Console → EC2 → Key Pairs)"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
