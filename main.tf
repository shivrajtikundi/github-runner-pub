provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_security_group" "terraform-sg" {
  name        = "terraform-sg"
  description = "Allow SSH and HTTP traffic"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS from anywhere
  }

  # Egress rules (allow outbound traffic to everywhere)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # All protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow outbound traffic to everywhere
  }
}

resource "aws_instance" "terraform" {
  ami           = "ami-0287a05f0ef0e9d9a" # Ubuntu 22.04 LTS AMI ID
  instance_type = "t2.micro" # Change instance type as needed
  key_name      = var.aws_key_pair
  security_groups = [aws_security_group.terraform-sg.name]

  tags = {
    Name = "Ubuntu-Instance"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Updating packages...'",
      "sudo apt-get update",
      "echo 'Installing Git...'",
      "sudo apt-get install -y git",
      "echo 'Creating folder: actions-runner'",
      "mkdir actions-runner && cd actions-runner",
      "echo 'Downloading runner package...'",
      "curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz",
      "echo 'Validating hash...'",
      "echo '29fc8cf2dab4c195bb147384e7e2c94cfd4d4022c793b346a6175435265aa278  actions-runner-linux-x64-2.311.0.tar.gz' | shasum -a 256 -c",
      "echo 'Extracting installer...'",
      "tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz",
      "cd ~/actions-runner && ./config.sh --url https://github.com/${var.github_organization}/${var.github_repo} --token ${var.github_token} --labels self-hosted --unattended",
      "echo 'Running ./svc.sh...'",
      "sudo ./svc.sh install",
      "sudo ./svc.sh start"
    ]
  }
}

variable "aws_region" {
  description = "AWS region"
  default     = "ap-south-1"
}

variable "aws_access_key" {
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
}

variable "aws_key_pair" {
  description = "EC2 Key Pair Name"
}

variable "private_key_path" {
  description = "Path to your private key"
}

variable "github_organization" {
  description = "GitHub organization name"
}

variable "github_repo" {
  description = "GitHub repository name"
}

variable "github_token" {
  description = "GitHub personal access token"
}

