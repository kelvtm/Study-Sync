resource "aws_instance" "example" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "too-dove-key"
  vpc_security_group_ids = [aws_security_group.too_sg.id]
  availability_zone      = var.zone


  tags = {
    Name    = "HelloWorld"
    Project = "Study-Sync"
  }

  provisioner "file" {
  source      = "web.sh"
  destination = "tmp/web.sh"
  }

 connection {
    type     = "ssh"
    user     = var.web_user
    password = file(too.dove-key.pem)
    host     = self.public_ip
}

    provisioner "remote-exec" {
        inline = [
        "chmod +x /tmp/web.sh",
        "sudo /tmp/web.sh"
        ]
    }       
}