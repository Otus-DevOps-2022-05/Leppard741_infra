variable "cloud_id" {
  description = "Cloud"
}
variable "folder_id" {
  description = "Folder"
}
variable "zone" {
  description = "zone"
  default     = "ru-central1-a"
}
variable "public_key_path" {
  description = "Public key path"
}
variable "subnet_id" {
  description = "Subnet"
}
variable "service_account_key_file" {
  description = "Service account path"
}
variable "private_key_path" {
  description = "path to private key"
}
variable "app_servers_count" {
  description = "app_servers_count"
  default     = 1
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-ruby"
}
variable db_disk_image {
  description = "Disk image for reddit db"
  default     = "reddit-mongo"
}
variable "environment" {
  description = "stage,prod"
}
#variable "image_id" {
#  description = "clear image"
#}
