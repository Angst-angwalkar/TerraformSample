terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
  access_key = "your access key"
  secret_key = "your secret key"
}

# Create a VPC


# variable declaration for private credentials:
# variables to be passed through command line.
# variable "access_key" {
#   type = string
# }

# variable declaration for private credentials:
# variables to be passed through command line.
# variable "secret_key" {
#   type = string
# }



/*
# Resource creation basic format:

resource "<provider>_<resource_type>" "name" {
    config options...
    key = some_value
    key2 = some_value2
}

*/


# resource "aws_instance" "my-second-server" {
#   /*
#   Resource creation basic with AWS EC2 instance.

#   */
#   ami           = "ami-0ac67a26390dc374d"
#   instance_type = "t2.micro"


#   /*
#   Added tag after terraform apply to perform modifications.
#   Commenting out or removing a resource declaration will apply a "terraform destroy" on the commented resource.

#   */

#   tags = {
#     Name = "amazon linux"
#   }
# }



/*
Project Implementation starting with Terraform.
Sample project with the following steps:
1. Create a VPC
2. Create a subnnet for the VPC
3. Create an internet gateway
4. Create a routing table
5. Connecting the route table with subnet using association aws resource
6. Create a security group for the vpc and subnets. Allow HTTPS, HTTP and SSH connections on ports 443, 80 and 2 respectively.
7. Create a network interface
8. Create and assign an elastic ip to the network interface.
9. Create an Ubuntu server and install / enable apache server.
*/







/*
Creating a VPC for the project application
*/

resource "aws_vpc" "prod-vpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "production"
  }
}



/*
Creating an internet gateway for the project application
Will be used for connecting to the instance using OpenSSH
*/
resource "aws_internet_gateway" "main-internet-gateway" {
  vpc_id = aws_vpc.prod-vpc.id
}




/*
Creating an aws routing table for the project application
Routing table is used for routing the networking and allowing connections to the internet.
*/
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-internet-gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.main-internet-gateway.id
  }

  tags = {
    Name = "prod-route-table"
  }
}


/*
Creating an aws subnet.
subnet is the network on which the application server will run and operate on.
needs association with the route table.
*/
resource "aws_subnet" "subnet-1" {
  # referencing a resource 
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "prod-subnet-1"
  }
}




/*
Associating the route table with the subnet
Association resource connects the route table we created above with the provided subnet id.
*/
resource "aws_route_table_association" "prod-route-association" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}






/*
Creating a security group with for the vpc and the subnets

Security group can be created individually and security group rules can be added individually
using the ingress and egress rules one by one.
In this scenario, we are creating the security groups with inline rules.
*/
resource "aws_security_group" "allow-web-sg" {
  name        = "allow_web_traffic"
  description = "Allow Web Traffic inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    # Rule for HTTPS
    description = "HTTPS"
    from_port   = 443
    # from_port and to_port specifies the range of ports that will allow TCP traffic.
    # we allow only single port.
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


    ingress {
    # Rule for HTTP
    description = "HTTP"
    from_port   = 80
    # from_port and to_port specifies the range of ports that will allow TCP traffic.
    # we allow only single port.
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


    ingress {
    # Rule for SSH connection allowance
    description = "SSH"
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
    Name = "allow_web"
  }
}




/*
Creating a network interface. Use an ip that was creating in the subnet creation.
*/
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow-web-sg.id]

  # attachment {
  #   instance     = aws_instance.test.id
  #   device_index = 1
  # }
}



/*
Creating a elastic ip address. We associate the private ip created in the network interface.
*/
resource "aws_eip" "one" {
  # vpc = true deprecated
  # now use domain = "vpc"
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"

  # terraform mostly does create the resources in the needed order by default.
  # some resources that depend on other need to be specified using depends_on flag
  depends_on = [ aws_internet_gateway.main-internet-gateway ]
}




/*
Creating an Ubuntu instance
ami copied from AWS EC2 instance page.
We also specify:
availability_zone, necessary to be the same as subnet availability_zone
network_interface, device_index has to be provided a value, usually started at 0 and network_interface_id uses nic created in above step.
*/
resource "aws_instance" "web_server_instance" {
  ami           = "ami-0776c814353b4814d"
  instance_type = "t2.micro"

  availability_zone = "eu-west-1a"
  key_name = "main-key"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install apache2 -y
  sudo systemctl start apache2
  sudo chown -R ubuntu:ubuntu /var/www/html
  sudo bash -c 'echo You just created a first successfull web server > /var/www/html/index.html'
  EOF
  tags = {
    Name = "web-server"
  }
}