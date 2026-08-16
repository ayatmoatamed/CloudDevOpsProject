variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_azs" {
  description = "Availability zones for the public subnets"
  type        = list(string)
   default     = ["us-east-1b", "us-east-1a"]
}


variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets used by EKS"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "private_subnet_azs" {
  description = "Availability zones for the private subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "project_name" {
  description = "Prefix used for naming and tagging resources"
  type        = string
  default     = "ivolve"
}