variable "cidr_block" {
  type = string
  description = "Value for the subnet CIDR"
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type = list(string)
  description = "Values for public subnet"
  default = [ "10.0.1.0/24", "10.0.2.0/24" ]
}

variable "private_subnet_cidrs" {
  type = list(string)
  description = "Values for private subnet"
  default = [ "10.0.3.0/24", "10.0.4.0/24" ]
}

variable "availability_zones" {
  type = list(string)
  description = "Values for Availability Zones"
  default = [ "us-east-1a", "us-east-1b", "us-east-1c" ]
}


variable "ami-id" {
  type = string
  description = "AMI Id to launch EC2 instance"
  default = "ami-0b49da0fc7d40b05a"
}