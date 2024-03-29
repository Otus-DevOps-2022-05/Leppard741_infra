resource "yandex_compute_instance" "app" {
  name = "app-${var.environment}"
  zone = var.zone
  labels = {
    tags = "app-${var.environment}"
  }
  resources {
    cores  = 2
    memory = 2
  }

  network_interface {
    subnet_id = var.subnet_id
    nat = true
  }

#  boot_disk {
#    initialize_params {
#      image_id = var.image_id
#    }
#  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  connection {
    type        = "ssh"
    host        = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user        = "ubuntu"
    agent       = false
    private_key = file(var.private_key_path)
  }

#  provisioner "file" {
#    content     = templatefile("${path.module}/files/puma.service.tftpl", { MONGODB_DATABASE_URL = var.database_ip })
#    destination = "/tmp/puma.service"
#  }
#  provisioner "remote-exec" {
#    script = "${path.module}/files/deploy.sh"
#  }
}
