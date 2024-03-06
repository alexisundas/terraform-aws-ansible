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
  region = "eu-central-1"
}

#aws instance creation
resource "aws_instance" "os1" {
  ami           = "ami-0f318687928e8af0b"
  instance_type = "t2.micro"
   key_name = "alexis-test"
  tags = {
    Name = "Terraform-OS"
  }
}

#IP of aws instance retrieved
output "op1"{
value = aws_instance.os1.public_ip
}

#ebs volume created
resource "aws_ebs_volume" "ebs"{
  availability_zone =  aws_instance.os1.availability_zone
  size              = 1
  tags = {
    Name = "myterra-ebs"
  }
}

#ebs volume attached to instance
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id = aws_ebs_volume.ebs.id
  instance_id = aws_instance.os1.id
  force_detach = true
}

#IP of aws instance copied to a file ip.txt in local system
resource "local_file" "ip" {
  content = aws_instance.os1.public_ip
  filename = "ip.txt"
}

#Connection to the Ansible control node usig SSH Connection
resource "null_resource" "nullremote" {
  depends_on = [ aws_instance.os1 ]
  connection {
    type = "ssh"
    user = "ec2-user"
    host = "${var.host}"
    private_key = file("C:/Users/Alexis/Desktop/Udemy/Project/terraform-jenkins-eks/alexis-test.pem")
  }
  #copying the ip.txt file to the Ansible control node from local system
  provisioner "file" {
    source      = "ip.txt"
    destination = "/home/ec2-user/aws-instance/ip"
  		   }
  #copying the ansible yml file to the Ansible control node from local system
  provisioner "file" {
    source      = "playbook.yml"
    destination = "/home/ec2-user/aws-instance/playbook.yml"
  		   }

  #command to run ansible playbook on remote Linux OS
  provisioner "remote-exec" {
    
    inline = [
	"cd /home/ec2-user/aws-instance/",
	"ansbile-playbook -i ip playbook.yml",
]
}
}

