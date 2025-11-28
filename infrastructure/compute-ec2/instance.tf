resource "aws_instance" "example" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "too-dove-key-file"
  vpc_security_group_ids = [aws_security_group.too_sg.id]
  availability_zone      = var.zone


  tags = {
    Name    = "Study-Sync-Web-Server"
    Project = "Study-Sync"
  }

  connection {
    type     = "ssh"
    user     = var.web_user
    private_key = file("./too-dove-key-file")
    host     = self.public_ip
    timeout = "5m"
  }

  # Copy .env.prod file
  provisioner "file" {
    source      = "~/Desktop/Study-Sync-Project/.env.production"  # Local file path
    destination = "/tmp/.env.prod"
  }

  provisioner "file" {
    source      = "web.sh"
    destination = "/tmp/web.sh"
  }


  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/web.sh",
      "sudo /tmp/web.sh"
    ]
  }
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > web_public_ip.txt"
  }
}

output "webpublicip" {
  value = aws_instance.example.public_ip
}
output "webprivatecip" {
  value = aws_instance.example.private_ip
}