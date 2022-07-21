resource "yandex_storage_bucket" "backend-s3" {
  access_key = var.access_key
  secret_key = var.secret_key
  bucket = "backend-s3"
}
