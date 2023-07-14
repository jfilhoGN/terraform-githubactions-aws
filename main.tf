
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "terraform_githubactions" {
  ami                         = data.aws_ami.amazon-linux-2.id
  instance_type               = "t2.micro"
  key_name                    = "access"
  subnet_id                   = var.terraform_githubactions_subnet_public_id
  vpc_security_group_ids      = [aws_security_group.terraform_githubactions_ssh_http.id]
  associate_public_ip_address = true

  tags = {
    Name = var.ec2_name
  }
}

variable "terraform_githubactions_vpc_id" {
  default = "vpc-01e5187351a131652"
}

variable "terraform_githubactions_subnet_public_id" {
  default = "subnet-09a5aa6de17452829"
}

variable "ec2_name" {
  type = string
}

resource "aws_security_group" "terraform_githubactions_ssh_http" {
  name        = "access_ssh"
  description = "Permite SSH e HTTP na instancia EC2"
  vpc_id      = var.terraform_githubactions_vpc_id

  ingress {
    description = "SSH to EC2"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP to EC2"
    from_port   = 80
    to_port     = 80
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
    Name = "access_ssh_e_http"
  }
}
