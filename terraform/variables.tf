variable "cloud_id" {
  description = "Cloud"
}
variable "folder_id" {
  description = "Folder"
}
variable "zone" {
  description = "zone"
  default     = "ru-central1-b"
}
variable "public_key_path" {
  description = "Public key path"
}
variable "image_id" {
  description = "Image"
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
