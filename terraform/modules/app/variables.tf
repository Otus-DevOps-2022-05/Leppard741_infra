variable "public_key_path" {
  description = "Public key path"
}
variable "subnet_id" {
  description = "Subnet"
}
variable "app_disk_image" {
  description = "Disk image for reddit app"
  default = "reddit-ruby"
}
variable "environment" {
  description = "stage, prod"
}
variable "zone" {
  description = "Zone"
  default     = "ru-central1-a"
}
variable "private_key_path" {
  description = "path to private key"
}
variable "database_ip" {
  description = "IP address of Mongodb server"
}
