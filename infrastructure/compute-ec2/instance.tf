resource "aws_instance" "study_sync1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "too-dove-key2"
  vpc_security_group_ids = [aws_security_group.too_sg.id]
  availability_zone      = var.zone

  # Bootstrap script runs on first boot
  user_data_base64 = base64encode(templatefile("${path.module}/user-data.sh", {
    env_content = file(pathexpand("~/Desktop/Study-Sync-Project/.env.production"))
  }))

  # This ensures user_data changes trigger replacement
  user_data_replace_on_change = true

  tags = {
    Name    = "Study-Sync-Web-Server"
    Project = "Study-Sync"
  }

  # local-exec for IP output
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > web_public_ip.txt"
  }
}

output "webpublicip" {
  value = aws_instance.study_sync1.public_ip
}

output "webprivatecip" {
  value = aws_instance.study_sync1.private_ip
}

output "ssh_connection" {
  value = "ssh -i ./too-dove-key-file ubuntu@${aws_instance.study_sync1.public_ip}"
  description = "SSH connection command"
}