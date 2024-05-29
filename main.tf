provider "aws" {
    region = "eu-west-1"

}


# variable declaration for private credentials:
# variables to be passed through command line.
variable "access_key" {
  type = string
}

# variable declaration for private credentials:
# variables to be passed through command line.
variable "secret_key" {
  type = string
}



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
    egress_only_gateway_id = aws_internet_gateway.main-internet-gateway.id
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


