provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

resource "aws_security_group" "docker_allow_all_in_vpc" {
  name = "docker_allow_all_in_vpc"
  description = "Allow all between machines of this sg, SSH only from WAN"

  ingress {
    self = true
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    self = true
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }

  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
  }
}

resource "aws_instance" "docker-node" {
    ami = "${var.aws_ami_id}"
    instance_type = "${var.aws_instance_type}"
    key_name = "jraffre"
    user_data = "${file("user-data/docker-bootstrap.sh")}"
    vpc_security_group_ids = ["${aws_security_group.docker_allow_all_in_vpc.id}"]
    ebs_block_device {
      device_name = "/dev/sdk"
      volume_size = "${var.aws_ebs_size}"
      volume_type = "gp2"
    }
    tags {
        Name = "docker-node"
    }
}

output "public_ip" {
  value = "${aws_instance.docker-node.public_ip}"
}

output "private_ip" {
  value = "${aws_instance.docker-node.private_ip}"
}
