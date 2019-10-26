#Define the AWS region 
variable "region" {
  type    = "string"
  default = "us-east-1"
  description = "The AWS region used"
}

#Define a map containing the AMI to use on EC2 for a given AWS region
variable "amis" {
  type = "map"
  default = {
    "us-east-1" = "ami-02eac2c0129f6376b"          #CentOS7 - us-east-1
    "us-west-2" = "ami-0f2b4fc905b0bd1f1"          #CentOS7 - us-east-2
  }
  description = "A map containing the AMI to use on EC2 for a given AWS region"
}

#Define the number of AWS EC2 instances to create for control nodes
variable "control_node_count" {
  type    = number
  default = 3
  description = "The number of AWS EC2 instances to create for control nodes"
}

#Define the number of AWS EC2 instances to create for worker nodes
variable "worker_node_count" {
  type    = number
  default = 3
  description = "The number of AWS EC2 instances to create for worker nodes"
}
