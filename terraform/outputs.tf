#Output the region used
output "region" {
  value = var.region
  description = "The AWS region used"
}

#Output the AMI used
output "ami" {
  value = var.amis[var.region]
  description = "The AMI used"
}

#Output the ELB DNS name
output "elb_instance" {
  value = "${aws_elb.loadbalancer1.dns_name}"
  description = "The DNS name of the Elastic Load Balancer"
}

#Output the EC2 instance private IP for control nodes
output "ec2_control_nodes" {
  value = "${aws_instance.control_nodes.*.private_ip}"
  description = "The private IPs of the EC2 instances for control nodes"
}

#Output the EC2 instance private IP for worker nodes
output "ec2_worker_nodes" {
  value = "${aws_instance.worker_nodes.*.private_ip}"
  description = "The private IPs of the EC2 instances for worker nodes"
}

