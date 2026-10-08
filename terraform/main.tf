resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project3-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "project3-public-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "project3-public-subnet-b"
  }
}
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "project3-igw"
  }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "project3-public-route-table"
  }
}
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Security group for the Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "project3-alb-sg"
  description = "Allow HTTP traffic to the load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project3-alb-sg"
  }
}

# Security group for EC2 web servers
resource "aws_security_group" "web" {
  name        = "project3-web-sg"
  description = "Allow HTTP traffic from the load balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project3-web-sg"
  }
}
# EC2 web server in Availability Zone A
resource "aws_instance" "web_a" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_a.id

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl enable nginx
              systemctl start nginx
              echo "<h1>Project 3 - Web Server A</h1><p>Availability Zone: us-east-1a</p>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "project3-web-server-a"
  }
}

# EC2 web server in Availability Zone B
resource "aws_instance" "web_b" {
  ami           = "ami-0c101f26f147fa7fd"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_b.id

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl enable nginx
              systemctl start nginx
              echo "<h1>Project 3 - Web Server B</h1><p>Availability Zone: us-east-1b</p>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "project3-web-server-b"
  }
}
