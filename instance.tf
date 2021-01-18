resource "aws_key_pair" "sshkey" {
  key_name   = "sshkey"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/*/ubuntu-bionic-18.04-*"] # Ubuntu Minimal Bionic
    }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "instances" {
  name        = "k3s-${var.resource_prefix}"
  description = "k3s-${var.resource_prefix}"
  }

resource "aws_instance" "server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  user_data = file("cloud-config-server.yml")
  key_name = aws_key_pair.sshkey.key_name
  vpc_security_group_ids = [aws_security_group.instances.id]
  tags = {
    Name = "k3s-server"
  }
provisioner "file" {
    source      = "AppBundle.yaml"
    destination = "AppBundleDeployment.yaml"
  }
  provisioner "file" {
    source      = "haproxy-ingress.yaml"
    destination = "haproxy-ing.yaml"
  }
  provisioner "remote-exec" {
    inline = [
      "sleep 5; sudo chmod +x AppBundleDeployment.yaml; sudo chmod +x haproxy-ing.yaml",
      "sudo kubectl create -f haproxy-ing.yaml",
      "sudo kubectl create -f  AppBundleDeployment.yaml",
    ]
  }
 provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sudo sed -i -e 's/\r$//' /tmp/script.sh",  # Remove the spurious CR characters.
      "sudo /tmp/script.sh",
    ]
  }
  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = var.INSTANCE_USERNAME
    private_key = file(var.PATH_TO_PRIVATE_KEY)
  }
}

resource "aws_instance" "worker" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  user_data = file("cloud-config-worker.yml")
  key_name = aws_key_pair.sshkey.key_name
  vpc_security_group_ids = [aws_security_group.instances.id]
  tags = {
    Name = "k3s-worker"
  }
  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = var.INSTANCE_USERNAME
    private_key = file(var.PATH_TO_PRIVATE_KEY)
  }
}

resource "aws_security_group_rule" "ssh" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "TCP"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instances.id
}
resource "aws_security_group_rule" "outbound_allow_all" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instances.id
}

resource "aws_security_group_rule" "inbound_allow_all" {
  type            = "ingress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = aws_security_group.instances.id
}

resource "aws_security_group_rule" "kubeapi" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "TCP"
  self            = true
  security_group_id = aws_security_group.instances.id
}
