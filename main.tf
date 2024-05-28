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


resource "aws_instance" "my-second-server" {
  /*
  Resource creation basic with AWS EC2 instance.

  */
  ami           = "ami-0ac67a26390dc374d"
  instance_type = "t2.micro"


  /*
  Added tag after terraform apply to perform modifications.
  Commenting out or removing a resource declaration will apply a "terraform destroy" on the commented resource.

  */

  tags = {
    Name = "amazon linux"
  }
}




/*
Referencing a resource in terraform:
*/

resource "aws_vpc" "first-vpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "first-vpc"
  }
}


resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.first-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "subnet-1"
  }
}
