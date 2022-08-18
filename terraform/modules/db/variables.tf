variable "public_key_path" {
  description = "Public key path"
}

variable "subnet_id" {
  description = "Subnet"
}

#variable "image_id" {
#  description = "Image"
#}

variable db_disk_image {
  description = "Disk image for reddit db"
  default = "reddit-mongo"
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
