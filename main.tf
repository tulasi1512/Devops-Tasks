provider "aws" {
  region = "ap-south-1"
}

## create a VPC ####
resource "aws_vpc" "vpc_test" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc_test"
  }
  lifecycle {
    prevent_destroy = true
  }
}

## create subnet-A ##
resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.vpc_test.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "SUBNET-A"
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

## create subnet-B ##
resource "aws_subnet" "subnet-b" {
  vpc_id            = aws_vpc.vpc_test.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name = "SUBNET-B"
  }
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

## Create EC2-instance in SUBNET-A ##
resource "aws_instance" "ec2_a" {
  ami           = "ami-083cf4acad89c8905"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.subnet_a.id

  tags = {
    Name = "EC2-SERVER-A"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

## create EC2-instance in subnet-b ##
resource "aws_instance" "ec2_b" {
  ami           = "ami-083cf4acad89c8905"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.subnet-b.id

  tags = {
    Name = "EC2-SERVER-B"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}
