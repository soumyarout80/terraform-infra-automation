#Module      : LABEL
#Description : Terraform label module variables.
variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "vpc_tags" {
  default = ""
}

variable "database_subnet_tags" {
  default = ""
}
variable "database_subnets" {
  default = ""
}
variable "azs" {
  default = ""
}
variable "single_nat_gateway" {
  default = ""
}
variable "database_subnet_suffix" {
  default = "database-subnet"
}
variable "private_subnets" {
  default = ""
}
variable "private_subnets_suffix" {
  default = "private-app-subnet"
}

variable "public_subnets" {
  default = ""
}
variable "public_subnets_suffix" {
  default = "public-subnet"
}
variable "create_vpc" {
  default = ""
}
variable "one_nat_gateway_per_az" {
  default = ""
}
variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "label_order" {
  type        = list(any)
  default     = []
  description = "Label order, e.g. `name`,`application`."
}

variable "attributes" {
  type        = list(any)
  default     = []
  description = "Additional attributes (e.g. `1`)."
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)."
}

#Module      : VPC
#Description : Terraform VPC module variables.
variable "vpc_enabled" {
  type        = bool
  default     = true
  description = "Flag to control the vpc creation."
}

variable "cidr_block" {
  type        = string
  default     = ""
  description = "CIDR for the VPC."
}

variable "instance_tenancy" {
  type        = string
  default     = "default"
  description = "A tenancy option for instances launched into the VPC."
}

variable "enable_dns_hostnames" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable DNS hostnames in the VPC."
}

variable "enable_dns_support" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable DNS support in the VPC."
}

variable "enable_classiclink" {
  type        = bool
  default     = false
  description = "A boolean flag to enable/disable ClassicLink for the VPC."
}

variable "enable_classiclink_dns_support" {
  type        = bool
  default     = false
  description = "A boolean flag to enable/disable ClassicLink DNS Support for the VPC."
}
