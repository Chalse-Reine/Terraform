resource "aws_vpc" "etc_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    name = "dev"
  }
}

resource "aws_subnet" "etc_public_subnet" {
  vpc_id                  = aws_vpc.etc_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    name = "dev-public"
  }
}

resource "aws_internet_gateway" "etc_internet_gateway" {
  vpc_id = aws_vpc.etc_vpc.id

  tags = {
    name = "dev-igw"
  }
}

resource "aws_route_table" "etc_public_rt" {
  vpc_id = aws_vpc.etc_vpc.id

  tags = {
    name = "dev-public-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.etc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.etc_internet_gateway.id
}

resource "aws_route_table_association" "etc_public_assoc" {
  subnet_id      = aws_subnet.etc_public_subnet.id
  route_table_id = aws_route_table.etc_public_rt.id
}

resource "aws_security_group" "etc_sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.etc_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "etc_auth" {
  key_name   = "etckey"
  public_key = file("~/.ssh/etckey.pub")
}

resource "aws_instance" "dev_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.etc_auth.id
  vpc_security_group_ids = [aws_security_group.etc_sg.id]
  subnet_id              = aws_subnet.etc_public_subnet.id
  user_data = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-node"
  }
}