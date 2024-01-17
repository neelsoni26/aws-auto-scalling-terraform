# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main"
  }
}

# Create Public subnet under main vpc for us-east-1a
resource "aws_subnet" "public_subnet_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.awsRegion}a"
  tags = {
    Name = "Public Subnet ${var.awsRegion}a"
  }
}

# Create Public subnet under main vpc for us-east-1b
resource "aws_subnet" "public_subnet_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.awsRegion}b"
  tags = {
    Name = "Public Subnet ${var.awsRegion}b"
  }
}

# Create internet gatewat under main vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    "Name" = "Internet GateWay"
  }
}

# Create route table for public subnet with internet gateway
resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Route Table"
  }
}

# associate route table with public subnets
resource "aws_route_table_association" "public-public_subnet_1a" {
  subnet_id      = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.route_table_public.id
}

resource "aws_route_table_association" "public-public_subnet_1b" {
  subnet_id      = aws_subnet.public_subnet_1b.id
  route_table_id = aws_route_table.route_table_public.id
}

# Create security group with inbound and outbound ports open under main VPC
resource "aws_security_group" "web_server" {
  vpc_id      = aws_vpc.main.id
  name_prefix = "HTTP-SSH-Access"
  # inbound port 80
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  # inbound port 22
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  # outbound port all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# A launch config with server installed
resource "aws_launch_configuration" "web_server_as" {
  image_id        = "ami-0c7217cdde317cfec"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_server.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "<html><body><h1>You're doing really Great</h1></body></html>" > index.html
              nohup python -m SimpleHTTPServer 80 &
              EOF
}

# Auto scalling group
resource "aws_autoscaling_group" "web_server_asg" {
  name                 = "web-server-asg"
  launch_configuration = aws_launch_configuration.web_server_as.name
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  health_check_type    = "EC2"
  vpc_zone_identifier  = [aws_subnet.public_subnet_1a.id, aws_subnet.public_subnet_1b.id]
}
