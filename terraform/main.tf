// Configure the Yandex.Cloud provider

provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

// Configure the modules

module "app" {
  source          = "/home/Leppard741_infra/terraform/modules/app"
  public_key_path = var.public_key_path
  app_disk_image  = var.app_disk_image
  subnet_id       = var.subnet_id
}

module "db" {
  source          = "/home/Leppard741_infra/terraform/modules/db"
  public_key_path = var.public_key_path
  db_disk_image   = var.db_disk_image
  subnet_id       = var.subnet_id
}

module "subnet" {
  source             = "/home/Leppard741_infra/terraform//modules/vpc"
  zone               = var.zone
  ipv4_subnet_blocks = var.ipv4_subnet_blocks
}
