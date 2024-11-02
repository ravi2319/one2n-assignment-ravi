resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  instance_tenancy = "default"
  tags = {
    "Name" = "Assignment VPC"
  }
}

resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    "Name" = "Public Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    "Name" = "Private Subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" = "Assignment IGW"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  depends_on = [ aws_subnet.public_subnets ]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_rt_association" {
  depends_on = [ aws_route_table.public_rt ]
  count = length(var.public_subnet_cidrs)
  subnet_id = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "server_security_group" {
  vpc_id = aws_vpc.main.id
  name = "allow_http"
  description = "Allow Internet Access to S3 Server"
  
  ingress {
    to_port = 80
    from_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    to_port = 0
    from_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    "Name" = "allow_http"
  }
}

resource "aws_iam_policy" "s3_access" {
  name = "s3-access-assignment"
  path = "/"
  description = "Policy to access S3 bucket"
  policy = jsonencode(
        {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AccesstoS3",
                "Effect": "Allow",
                "Action": [
                    "s3:ListBucket",
                    "s3:GetObject*"
                ],
                "Resource": [
                    "arn:aws:s3:::one2n-assignment-ravi-1",
                    "arn:aws:s3:::one2n-assignment-ravi-1/*"
                ]
            }
        ]
    }
  )
}

resource "aws_iam_role" "s3_role" {
  name = "EC2ServerAssignment"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "Statement1"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role = aws_iam_role.s3_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.s3_role.name
}

resource "aws_instance" "instance" {
  ami = var.ami-id
  instance_type = "t4g.small"
  security_groups = [ aws_security_group.server_security_group.id ]
  subnet_id = aws_subnet.public_subnets[0].id
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  tags = {
    "Name" = "Server"
  }
}