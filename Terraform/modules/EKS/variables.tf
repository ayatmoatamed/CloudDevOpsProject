variable "vpc_id" {
  description = "VPC ID passed from Network module"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS worker nodes"
  type        = list(string)
}
