provider "aws" {
  region = "ap-south-1"
}

# VPC
resource "aws_vpc" "vpc_test" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc_test"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

# Subnet A
resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.vpc_test.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "SUBNET-A"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

# Subnet B
resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.vpc_test.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "SUBNET-B"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_test.id

  tags = {
    Name = "IGW"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

# Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PUBLIC-RT"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

# Route Table Association A
resource "aws_route_table_association" "subnet_a_assoc" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

# Route Table Association B
resource "aws_route_table_association" "subnet_b_assoc" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group
resource "aws_security_group" "web_sg" {
  name   = "web_sg"
  vpc_id = aws_vpc.vpc_test.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WEB-SG"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

# EC2 Server A
resource "aws_instance" "ec2_a" {
  ami                    = "ami-083cf4acad89c8905"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet_a.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

user_data = <<-EOF
               #!/bin/bash
               apt update -y
               apt install -y apache2
               systemctl enable apache2
               systemctl start apache2
               ech

  tags = {
    Name = "EC2-SERVER-A"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

# EC2 Server B
resource "aws_instance" "ec2_b" {
  ami                    = "ami-083cf4acad89c8905"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet_b.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
               #!/bin/bash
               apt update -y
               apt install -y apache2
               systemctl enable apache2
               systemctl start apache2
               echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html
               EOF

  tags = {
    Name = "EC2-SERVER-B"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

# Target Group
resource "aws_lb_target_group" "tg" {
  name     = "terraform-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_test.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

# Target Group Attachment A
resource "aws_lb_target_group_attachment" "ec2_a_attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.ec2_a.id
  port             = 80
}

# Target Group Attachment B
resource "aws_lb_target_group_attachment" "ec2_b_attach" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.ec2_b.id
  port             = 80
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "terraform-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.web_sg.id]

  subnets = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id
  ]

  tags = {
    Name = "TERRAFORM-ALB"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [tags]
  }
}

# Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Outputs
output "elb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "subnet_a_availability_zone" {
  value = aws_subnet.subnet_a.availability_zone
}

output "subnet_b_availability_zone" {
  value = aws_subnet.subnet_b.availability_zone
}
