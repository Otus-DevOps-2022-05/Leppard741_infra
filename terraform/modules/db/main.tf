resource "yandex_compute_instance" "db" {
  name = "db-${var.environment}"
  zone = var.zone
  labels = {
    tags = "db-${var.environment}"
  }

  resources {
    cores  = 2
    memory = 2
  }

  network_interface {
    subnet_id = var.subnet_id
    nat = true
  }

  connection {
    type        = "ssh"
    host        = yandex_compute_instance.db.network_interface.0.nat_ip_address
    user        = "ubuntu"
    agent       = false
    private_key = file(var.private_key_path)
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

#  boot_disk {
#    initialize_params {
#      image_id = var.image_id
#    }
#  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image
    }
  }

#   provisioner "remote-exec" {
#    script = "${path.module}/files/config_mongodb.sh"
#  }
}
