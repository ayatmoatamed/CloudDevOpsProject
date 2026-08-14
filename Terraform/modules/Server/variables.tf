variable "vpc_id" {
  description = "VPC ID passed from Network module"
  type        = string
}

variable "public_subnet_id" {
  description = "Public Subnet ID where Jenkins EC2 will be deployed"
  type        = string
}


variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  type        = string
  default     = "t3.small"
}