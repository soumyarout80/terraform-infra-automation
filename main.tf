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
  subnet_id = aws_subnet.public[0].id

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
# Private routes
###################################################################################
resource "aws_route_table" "private" {
  count = 1
  vpc_id = aws_vpc.default.id
  tags = {
    "Name" = "private-route-table"
  }

}
resource "aws_route" "private_nat_gateway" {
  count = 1

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.default.*.id, count.index)

  timeouts {
    create = "5m"
  }
}

###################################################################################
# Public routes
###################################################################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id
  tags = {
    "Name" = "public-route-table"
  }

}
resource "aws_route" "public_ig" {
  count = 1

  route_table_id         = element(aws_route_table.public.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id

  timeouts {
    create = "5m"
  }
}
###################################################################################
# Route table association
###################################################################################
resource "aws_route_table_association" "private" {
  count = 3

  subnet_id = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(
    aws_route_table.private.*.id,
    count.index,
  )
}

resource "aws_route_table_association" "database" {
  count = 3

  subnet_id = element(aws_subnet.database.*.id, count.index)
  route_table_id = element(
    coalescelist(aws_route_table.database.*.id, aws_route_table.private.*.id),
    count.index,
  )
}


resource "aws_route_table_association" "public" {
  count = 3

  subnet_id = element(aws_subnet.public.*.id, count.index)
  route_table_id = element(aws_route_table.public.*.id, count.index)
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
# Public subnet
###################################################################################
resource "aws_subnet" "public" {
  count = 3
  vpc_id                          = aws_vpc.default.id
  cidr_block                      = element(concat(var.public_subnets, [""]), count.index)
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null


  tags = {
      "Name" = format(
        "%s-${var.public_subnets_suffix}-%s",
        var.name,
        element(var.azs, count.index),
      )
    }
}


