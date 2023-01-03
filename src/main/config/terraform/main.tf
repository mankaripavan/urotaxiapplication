terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "urotaxi2-tfstate-bucket"
    region = "ap-south-1"
    key = "terraform.tfstate"
    dynamodb_table = "urotaxi-terraform-lock"    
  }
}
provider "aws" {
    region = "ap-south-1"  
}
resource "aws_vpc" "urotaxivpc" {
    cidr_block = var.urotaxivpc_cidr
    tags = {
      "Name" = "urotaxivpc"
    }  
}
resource "aws_subnet" "urotaxipubsn1" {
    cidr_block = var.urotaxipubsn1_cidr
    vpc_id = aws_vpc.urotaxivpc.id
    tags = {
      "Name" = "urotaxipubsn1"
    }  
}
resource "aws_subnet" "urotaxiprvsn2" {
    cidr_block = var.urotaxiprvsn2_cidr
    vpc_id = aws_vpc.urotaxivpc.id
    tags = {
      "Name" = "urotaxiprvsn2"
    } 
}
resource "aws_subnet" "urotaxiprvsn3" {
    cidr_block = var.urotaxiprvsn3_cidr
    vpc_id = aws_vpc.urotaxivpc.id
    tags = {
      "Name" = "urotaxiprvsn3"
    } 
}
resource "aws_internet_gateway" "urotaxiigw" {
    vpc_id = aws_vpc.urotaxivpc.id
    tags = {
      "Name" = "urotaxiigw"
    }  
}
resource "aws_route_table" "urotaxiigwrt" {
    vpc_id = aws_vpc.urotaxivpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.urotaxiigw.id
    }
    tags = {
      "Name" = "urotaxiigwrt"
    }  
}
resource "aws_route_table_association" "urotaxiigwrtassociation" {
    subnet_id = aws_subnet.urotaxipubsn1.id
    route_table_id = aws_route_table.urotaxiigwrt.id 
}
resource "aws_security_group" "urotaxiec2sg" {
    vpc_id = aws_vpc.urotaxivpc.id
    ingress {
        from_port = "8080"
        to_port = "8080"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/1"]
    }
    tags = {
        "Name" = "urotaxiec2sg"
    }  
}
resource "aws_security_group" "urotaxidbsg" {
    vpc_id = aws_vpc.urotaxivpc.id
    ingress {
        from_port = "3306"
        to_port = "3306"
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }  
}
resource "aws_db_subnet_group" "urotaxidbsng" {
    name = "urotaxidbsng"
    subnet_ids = [aws_subnet.urotaxiprvsn2.id, aws_subnet.urotaxiprvsn3.id]
    tags = {
      "Name" = "urotaxidbsng"
    }  
}
resource "aws_db_instance" "urotaxidb" {
    vpc_security_group_ids = [aws_security_group.urotaxidbsg.id]
    allocated_storage = 10
    db_name = "mydb"
    engine = "mysql"
    engine_version = var.db_engine_version
    instance_class = var.db_instance_class
    username = var.db_username
    password = var.db_password
    skip_final_snapshot = true
    db_subnet_group_name = aws_db_subnet_group.urotaxidbsng.name  
}
resource "aws_key_pair" "urotaxikp" {
    key_name = "urotaxikey"
    public_key = var.urotaxi_public_key  
}
resource "aws_instance" "urotaxiec2" {
    vpc_security_group_ids = [aws_security_group.urotaxiec2sg.id]
    subnet_id = aws_subnet.urotaxipubsn1.id
    ami = var.urotaxi_ami
    instance_type = var.urotaxi_instance_type
    key_name = aws_key_pair.urotaxikp.key_name
    associate_public_ip_address = true  
}