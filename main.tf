provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "app-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.environment}-vpc"
  }
}

module "app-subnet" {
  source = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone = var.avail_zone
  environment = var.environment
  vpc_id = aws_vpc.app-vpc.id
  default_route_table_id = aws_vpc.app-vpc.default_route_table_id
}

module "app-server"{
  source = "./modules/webserver"
  vpc_id = aws_vpc.app-vpc.id
   ip = var.ip
   environment = var.environment
   public_key_location =var.public_key_location
   instance_type = var.instance_type
   subnet_id = module.app-subnet.subnet.id
   avail_zone =var.avail_zone
}
