variable "aws_region" {
  description = "AWS region. Pluralsight sandbox only allows us-east-1 or us-west-2."
  type        = string
  default     = "us-west-2"

  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.aws_region)
    error_message = "Sandbox only permits us-east-1 or us-west-2."
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "sandbox-eks"
}

variable "cluster_version" {
  description = "Kubernetes version. Must be a version in EKS standard support (not extended) per sandbox rules."
  type        = string
  default     = "1.36"
}

variable "vpc_cidr" {
  description = "CIDR block for the sandbox VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across (2 is enough for EKS HA requirements)."
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (one per AZ)."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group. Sandbox only allows t2/t3/t3a/t4g in micro/small/medium sizes."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes. Kept low — sandbox caps total concurrent EC2 instances at 9."
  type        = number
  default     = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "node_disk_size" {
  description = "EBS volume size (GB) per worker node. Sandbox caps EC2 volumes at 100GB."
  type        = number
  default     = 20
}
