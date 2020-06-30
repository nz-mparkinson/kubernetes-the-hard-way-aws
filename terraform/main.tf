#Define the AWS provider
provider "aws" {
  profile    = "default"
  region     = var.region
}



#Define a VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block       = "10.240.0.0/16"

  tags = {
    Name = "terraform_vpc"
  }
}

#Define a VPC Internet Gateway
resource "aws_internet_gateway" "terraform_gw" {
  vpc_id     = "${aws_vpc.terraform_vpc.id}"

  tags = {
    Name = "terraform_gw"
  }
}

#Define a Subnet
resource "aws_subnet" "terraform_subnet" {
  vpc_id     = "${aws_vpc.terraform_vpc.id}"
  cidr_block = "10.240.0.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "terraform_subnet"
  }
}



#Define a Security Group
resource "aws_security_group" "terraform_security_group" {
  name        = "terraform_security_group"
  description = "Terraform Security Group"
  vpc_id      = "${aws_vpc.terraform_vpc.id}"

  tags = {
    Name = "terraform_security_group"
  }
}

#Define Security Group egress rules
resource "aws_security_group_rule" "egress_allow_all" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  description     = "Allow all inbound"

  security_group_id = "${aws_security_group.terraform_security_group.id}"
}

#Define Security Group ingress rules
resource "aws_security_group_rule" "ingress_allow_all_internal" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "all"
  source_security_group_id = "${aws_security_group.terraform_security_group.id}"
  description     = "Allow All inbound internal"

  security_group_id = "${aws_security_group.terraform_security_group.id}"
}

resource "aws_security_group_rule" "ingress_allow_http" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  description     = "Allow HTTP inbound"

  security_group_id = "${aws_security_group.terraform_security_group.id}"
}

resource "aws_security_group_rule" "ingress_allow_https" {
  type            = "ingress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  description     = "Allow HTTPS inbound"

  security_group_id = "${aws_security_group.terraform_security_group.id}"
}

resource "aws_security_group_rule" "ingress_allow_ssh" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  description     = "Allow SSH inbound"

  security_group_id = "${aws_security_group.terraform_security_group.id}"
}



#Define a number of EC2 Instances for control nodes
resource "aws_instance" "control_nodes" {
  ami           = var.amis[var.region]
  instance_type = "t2.micro"
  key_name      = "aws-key-pair"
  tags = {
    Name = "control_nodes"
  }
  root_block_device {
    delete_on_termination = "true"
  }

  #security_groups       = ["${aws_security_group.terraform_security_group.name}"]
  vpc_security_group_ids = ["${aws_security_group.terraform_security_group.id}"]
  subnet_id              = "${aws_subnet.terraform_subnet.id}"
  private_ip             = "${cidrhost(aws_vpc.terraform_vpc.cidr_block, 10 + count.index)}"

  #Create a number of EC2 instances for control nodes
  count = var.control_node_count
}

#Define a number of EC2 Instances for worker nodes
resource "aws_instance" "worker_nodes" {
  ami           = var.amis[var.region]
  instance_type = "t2.micro"
  key_name      = "aws-key-pair"
  tags = {
    Name = "worker_nodes"
    Test = "123"
  }
  root_block_device {
    delete_on_termination = "true"
  }

  #security_groups       = ["${aws_security_group.terraform_security_group.name}"]
  vpc_security_group_ids = ["${aws_security_group.terraform_security_group.id}"]
  subnet_id              = "${aws_subnet.terraform_subnet.id}"
  private_ip             = "${cidrhost(aws_vpc.terraform_vpc.cidr_block, 20 + count.index)}"

  #Create a number of EC2 instances for worker nodes
  count = var.worker_node_count
}



#Get the details of the AWS service account
data "aws_elb_service_account" "main" {}

#Define a S3 Bucket
resource "aws_s3_bucket" "storage1" {
  bucket = "control-node-storage1"
  acl    = "private"
  force_destroy           = "true"

  tags = {
    Name        = "control-node-storage1"
    Environment = "Dev"
  }

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::control-node-storage1/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.main.arn}"
        ]
      }
    }
  ]
}
POLICY
}



#Define a EC2 Load Balancer
resource "aws_elb" "loadbalancer1" {
  name               = "loadbalancer1"
  #availability_zones = "${aws_instance.control_nodes.*.availability_zone}"

  access_logs {
    bucket        = "control-node-storage1"
    bucket_prefix = "loadbalancer1"
    interval      = 60
  }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

#  listener {
#    instance_port      = 8000
#    instance_protocol  = "http"
#    lb_port            = 443
#    lb_protocol        = "https"
#    ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
#  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/search.html"
    interval            = 30
  }

  instances                   = "${aws_instance.control_nodes.*.id}"
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "loadbalancer1"
  }

  security_groups = ["${aws_security_group.terraform_security_group.id}"]
  subnets         = ["${aws_subnet.terraform_subnet.id}"]
}



