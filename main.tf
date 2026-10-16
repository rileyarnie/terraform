provider "aws" {
  region = "us-east-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable environment {}
variable ip {}
variable instance_type{}
variable key_name {}
variable public_key_location{}

resource "aws_vpc" "app-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.environment}-vpc"
  }
}


resource "aws_subnet" "app-subnet-1" {
  vpc_id = aws_vpc.app-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.environment}-subnet-1"
  }
}

resource "aws_internet_gateway" "app-igw" {
  vpc_id = aws_vpc.app-vpc.id
}

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.app-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app-igw.id
  }

  tags={
    Name: "${var.environment}-main-rtb"
  }
}

resource "aws_default_security_group" "app-default-sg" {
  vpc_id = aws_vpc.app-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = ["${var.ip}"]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags={
    Name: "${var.environment}-default-sg"
  }
}

data "aws_ami" "latest-amazon-linux-image"{
  most_recent = true
  owners = ["amazon"]
filter {
  name = "virtualization-type"
  values = ["hvm"]
}
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.public_key_location)

}

resource "aws_instance" "app-server"{
  ami = "ami-0ed59cbb87dfa8dba"
  instance_type = var.instance_type

  subnet_id = aws_subnet.app-subnet-1.id
  vpc_security_group_ids = ["${aws_default_security_group.app-default-sg.id}"]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

  user_data = file("entry-script.sh")

  user_data_replace_on_change = true

  tags={
    Name: "${var.environment}-server"
  }
}


output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
}

output "ec2_public_ip" {
  value = aws_instance.app-server.public_ip
}
