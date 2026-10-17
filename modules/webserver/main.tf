resource "aws_default_security_group" "app-default-sg" {
  vpc_id = var.vpc_id

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

  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_default_security_group.app-default-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

  user_data = file("${path.module}/entry-script.sh")

  user_data_replace_on_change = true

  tags={
    Name: "${var.environment}-server"
  }
}
