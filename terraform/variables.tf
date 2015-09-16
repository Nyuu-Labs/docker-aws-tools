variable "aws_access_key" {
  description = "AWS access key token"
}

variable "aws_secret_key" {
  description = "AWS secret key token"
}

variable "aws_keypair" {
  description = "AWS keypair name"  
}

variable "aws_region" {
  default = "eu-central-1"
  description = "AWS region to use"
}

variable "aws_ami_id" {
  default = "ami-9e656583"
  description = "AMI ID for created instances"
}

variable "aws_instance_type" {
  default = "t2.micro"
  description = "Instance type to use"
}


variable "aws_ebs_size" {
  default = 20
  description = "EBS size for docker root"
}
