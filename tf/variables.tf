variable "service_ports" {
  type        = list(object({
    description  = string
    port         = number
    protocol     = string
  }))
  default     = [
    {
      description = "SSH"
      port        = 22
      protocol    = "tcp"
    },
    {
      description = "react"
      port        = 3000
      protocol    = "tcp"
    },
    {
      description = "fastapi"
      port        = 5000
      protocol    = "tcp"
    },
    {
      description = "proxy"
      port        = 8080
      protocol    = "tcp"
    },
    {
      description = "EPAS"
      port        = 5444
      protocol    = "tcp"
    }]
}

variable "ssh_user" {
  type        = string
  default     = "ubuntu"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
  default     = "vpc-05a63bf0db2b1539d"
}

variable "az" {
  type        = string
  default     = "us-west-1a"
}

variable "cidr_block" {
  type        = string
  default     = "10.2.0.0/24"
}

variable "aws_region" {
  type        = string
  default     = "us-west-1"
}

# VPC
variable "public_cidrblock" {
  description = "Public CIDR block"
  type        = string
  default     = "0.0.0.0/0"
}

variable "private_cidrblock" {
  description = "Private CIDR block"
  type        = string
  default     = "127.0.0.1/32"
}

# IAM Force Destroy
variable "user_force_destroy" {
  description = "Force destroying AWS IAM User and dependencies"
  type        = bool
  default     = true
}

variable "custom_security_group_id" {
  description = "Security Group assign to the instances. Example: 'sg-12345'."
  type        = string
  default     = ""
}

variable "created_by" {
  type        = string
  description = "EDB terraform AWS"
  default     = "EDB terraform AWS"
}

variable "ami_id" {
  type        = string
  description = "AMI ID"
  default     = "ami-0d50e5e845c552faf"
}

variable "instance_type" {
  type       = string
  default    = "r6i.2xlarge"
}

variable "key_name" {
  type       = string
  default    = "richyen_vm"
}
