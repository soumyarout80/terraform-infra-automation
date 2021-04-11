# Managed By : Soumya Ranjan Rout
# Description : This Script is used to create VPC, Subnet, Internet Gateway and EC2 instances.

###################################################################################
#Module      : VPC
#Description : Terraform module to create VPC resource on AWS.
###################################################################################
resource "aws_vpc" "default" {

  cidr_block                       = var.cidr_block
  instance_tenancy                 = var.instance_tenancy
  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_dns_support               = var.enable_dns_support
  enable_classiclink               = var.enable_classiclink
  enable_classiclink_dns_support   = var.enable_classiclink_dns_support
  assign_generated_ipv6_cidr_block = true
  tags = {
    "Name" = "my-test-vpc"
  }
}
###################################################################################
#Module      : Elastic IP
#Description : Terraform module which creates Elastic IP resources on AWS
###################################################################################
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    "Name" = "Nat-elastic-ip"
  }
}
###################################################################################
#Module      : NAT GATEWAY
#Description : Terraform module which creates Nat Geteway resources on AWS
###################################################################################
resource "aws_nat_gateway" "default" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public.id

  tags = {
    "Name" =  format("%s-nat", var.name)
  }

  depends_on = [aws_internet_gateway.default]
}
###################################################################################
#Module      : INTERNET GATEWAY
#Description : Terraform module which creates Internet Geteway resources on AWS
###################################################################################
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
  tags = merge(
    var.tags,
    {
      "Name" = format("%s-igw", var.name)
    }
  )
}

###################################################################################
# Database subnet
###################################################################################
resource "aws_subnet" "database" {
  count = 3

  vpc_id                          = aws_vpc.default.id
  cidr_block                      = element(concat(var.database_subnets, [""]), count.index)
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null


  tags = {
      "Name" = format(
        "%s-${var.database_subnet_suffix}-%s",
        var.name,
        element(var.azs, count.index),
      )
    }
}
###################################################################################
# Database routes
###################################################################################
resource "aws_route_table" "database" {
  count = 1
  vpc_id = aws_vpc.default.id

  tags = {
    "Name" = "database-route-table"
  }

}
resource "aws_route" "database_nat_gateway" {
  count = 1

  route_table_id         = element(aws_route_table.database.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.default.*.id, count.index)

  timeouts {
    create = "5m"
  }
}
###################################################################################
# Private subnet
###################################################################################
resource "aws_subnet" "private" {
  count = 3

  vpc_id                          = aws_vpc.default.id
  cidr_block                      = element(concat(var.private_subnets, [""]), count.index)
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null


  tags = {
      "Name" = format(
        "%s-${var.private_subnets_suffix}-%s",
        var.name,
        element(var.azs, count.index),
      )
    }
}

###################################################################################
# Private subnet
###################################################################################
resource "aws_subnet" "public" {
  vpc_id                          = aws_vpc.default.id
  cidr_block                      = var.public_subnets
  availability_zone               = var.azs[0]


  tags = {
      "Name" = format(
        "%s-${var.public_subnets_suffix}-%s",
        var.name,
        var.azs[0]
      )
    }
}