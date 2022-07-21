terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "backend-s3"
    region     = "ru-central1"
    key        = "stage.tfstate"
    access_key = "YCAJEy7Bf1bd9Rx5tzjxBIVmn"
    secret_key = "YCOWKMTFGskvqpWfZFO6JUNTux9LpAVg5kvhZ7zf"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
