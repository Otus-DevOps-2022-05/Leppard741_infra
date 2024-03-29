// Configure the Yandex.Cloud provider

provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

// Configure the modules

  module "app" {
  source            = "./modules/app"
  public_key_path   = var.public_key_path
  private_key_path  = var.private_key_path
  subnet_id         = module.subnet.app_subnet_id
  zone              = var.zone
  environment       = var.environment
  database_ip       = module.db.external_ip_address_db
}

module "db" {
  source           = "./modules/db"
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  subnet_id        = module.subnet.app_subnet_id
  zone             = var.zone
  environment      = var.environment
}

module "subnet" {
  source             = "./modules/vpc"
  zone               = var.zone
  ipv4_subnet_blocks = var.ipv4_subnet_blocks
}
