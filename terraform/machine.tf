resource "aws_instance" "machine01" {
  ami                         = "ami-007fae589fdf6e955" // "ami-2757f631"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.sg_acme.id]

  root_block_device {
    volume_size = 20 #20 Gb
  }

  tags = {
    Name        = "${var.author}.machine03"
    Author      = var.author
    Date        = "2020.02.21"
    Environment = "LAB"
    Location    = "Paris"
    Project     = "ACME"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.key_path)
  }

  provisioner "file" {
    source      = "file1.txt"
    destination = "/home/ec2-user/file1.txt"
  }
  provisioner "file" {
    content     = <<EOF
{
    "log-driver": "awslogs",
    "log-opts": {
      "awslogs-group": "docker-logs-test",
      "tag": "{{.Name}}/{{.ID}}"
    }
}
EOF
    destination = "/home/ec2-user/daemon.json"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y docker httpd-tools",
      "sudo usermod -a -G docker ec2-user",
      "sudo chkconfig docker on",
      "sudo service docker start",
      "export portainerpass=${var.portainerPassword}",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "portainerpass=$(docker run --rm httpd:2.4-alpine htpasswd -nbB admin ${var.portainerPassword} | cut -d ':' -f 2)",
      "docker run -d --name portainer -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock portainer/portainer --admin-password $portainerpass",
      "docker run -d --name randomapp -p 5000:5000 alexgue/randomapp"
    ]
  }



}
