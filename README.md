
  GNU nano 6.2                                                                                                                                                                                                                                                                                                                                                                                                          README.md *                                                                                                                                                                                                                                                                                                                                                                                                                 
# Leppard741_infra
Leppard741 Infra repository OTUS DevOps 2022
## Instance details
bastion_IP = 51.250.88.101
someinternalhost_IP = 10.128.0.4
## YC deploy app details
testapp_IP = 51.250.87.119
testapp_port = 9292

## Packer homework

### 1) Параметризируйте созданный вами шаблон.

1.1) Необходимо создать файл **variables.json** и задать значения переменным в качестве примера показан и закоммичен **variables.json.examples**:

    { 
    "folder_id": "iddqd",
    "source_image_family": "iddt",
    "key_file": "./idkfa.json",
    "ssh_user": "doomslayer"
    }

1.2) После этого вносим изменения в **ubuntu16.json**

    {
        "variables": {
            "service_account_key_file": "",
            "folder_id": "",
            "source_image_family": "",
            "ssh_username": ""
        },
        "builders": [
            {
                "type": "yandex",
                "service_account_key_file": "{{user `service_account_key_file`}}",
                "folder_id": "{{user `folder_id`}}",
                "source_image_family": "{{user `source_image_family`}}",
                "image_name": "reddit-base-{{timestamp}}",
                "image_family": "reddit-base",
                "ssh_username": "{{user `ssh_username`}}",
                "use_ipv4_nat": "true",
                "platform_id": "standard-v1"
            }
        ],
        "provisioners": [
            {
                "type": "shell",
                "script": "/scripts/install_ruby.sh",
                "execute_command": "sudo {{.Path}}"
            },
            {
                "type": "shell",
                "script": "/scripts/install_mongodb.sh",
                "execute_command": "sudo {{.Path}}"
            }
        ]
    }


1.3) Далее для сборки образа запускаем packer build -var-file=variables.json ubuntu16.json после чего будет создан образ и присвоен id.

### 2) Построение bake-образа

2.1) Была добавлена переменная в **variables** в части **image_family** и описаны провиженеры с добавлением юнита и установкой reddit с его зависимостями

    {
        "variables": {
            "service_account_key_file": "",
            "folder_id": "",
            "source_image_family": "",
            "ssh_username": "",
            "image_family": ""
        },
        "builders": [
            {
                "type": "yandex",
                "service_account_key_file": "{{user `service_account_key_file`}}",
                "folder_id": "{{user `folder_id`}}",
                "source_image_family": "{{user `source_image_family`}}",
                "image_name": "reddit-full-{{timestamp}}",
                "image_family": "{{user `image_family`}}",
                "ssh_username": "{{user `ssh_username`}}",
                "use_ipv4_nat": "true",
                "platform_id": "standard-v1"
            }
        ],
        "provisioners": [
     {
                "type": "file",
                "source": "/home/Leppard741_infra/packer/Files/reddit.service",
                "destination": "/tmp/reddit.service"
            },
            {
                "type": "shell",
                "script": "/home/Leppard741_infra/packer/Files/startup_script.sh",
                "execute_command": "sudo {{.Path}}"
            }
        ]
    }

2.2) Содержимое юнита systemd


    [Unit]
    Description="Reddit"
    After=network.target
    
    [Service]
    Type=simple
    WorkingDirectory=/app/reddit
    ExecStart=/usr/local/bin/puma
    
    [Install]
    WantedBy=multi-user.target

2.3) После выполенения процедуры сборки образа - получаем образ с предустановленым и готовым к работе reddit

### 3) Автоматизация создания ВМ

3.1) После сборки образа с предустановленным и готовым к работе reddit получает id этого образа и собираем скрипт для сборки инстанса через YC `yc-reddit-bake.sh`:

    #!/bin/sh
    yc compute instance create  
    --name reddit-app-bake  
    --hostname reddit-app-bake  
    --memory=4  
    --create-boot-disk image-id=fd8qpdnpksdublj72a9g,size=10GB  
    --network-interface subnet-name=net-1-ru-central1-b,nat-ip-version=ipv4  
    --metadata serial-port-enable=1  
    --ssh-key ~/.ssh/appuser.pub  
    --zone ru-central1-b

На выходе получаем инстанс с работающим приложением reddit

## Terraform 1 Homework

### 1) Самостоятельные задания
#### 1.1) Определите input переменную для приватного ключа, использующегося в определении подключения для провижинеров (connection)
Переменная была добавлена в terraform.tfvars и добавлено описание в variables.tf, секция **connection** для провижинеров теперь выглядит так:

      connection {
        type        = "ssh"
        host        = self.network_interface.0.nat_ip_address
        user        = "ubuntu"
        agent       = false
        private_key = file(var.private_key_path)
      }
#### 1.2) Определите input переменную для задания зоны в ресурсе  "yandex_compute_instance" "app". У нее  должно  быть значение  по умолчанию
Переменная была добавлена в terraform.tfvars и добавлено описание в variables.tf, секция **resourse** теперь выглядит так:

    resource "yandex_compute_instance" "app" {
      name  = "reddit-app-${count.index}"
      count = var.app_servers_count
      zone = var.zone
#### 1.3) Так как в репозиторий не попадет ваш terraform.tfvars, тонужно сделать рядом файл  terraform.tfvars.example, в котором будут указаны переменные для образца
Содержимое **terraform.tfvars.example** :

    cloud_id                 = "ClOuDiD123456789"
    folder_id                = "FoLdErId123456789"
    zone                     = "ru-central1-a"
    image_id                 = "ImAgEiD123456789"
    public_key_path          = "~/.ssh/ubuntu.pub"
    subnet_id                = "SuBnEtId123456789"
    service_account_key_file = "/home/terraform.json"
    private_key_path         = "~/.ssh/ubuntu"
### Задание с ** №1
Создайте файл  lb.tf  и опишите в нем в коде terraform создание  HTTP балансировщика, направляющего трафик на наше  развернутое приложение на инстансе  reddit-app. Проверьте доступность приложения по адресу балансировщика. Добавьте в output переменные адрес балансировщика
Содержимое **lb.tf**:

    resource "yandex_lb_network_load_balancer" "lb" {
      name ="my-loadbalancer"
    
      listener {
        name        = "my-listener"
        port        = 80
        target_port = 9292
        protocol    = "tcp"
        external_address_spec {
          ip_version = "ipv4"
        }
      }
    
      attached_target_group {
        target_group_id = yandex_lb_target_group.lb_tg.id
        healthcheck {
          name = "http"
          http_options {
            port = 9292
          }
        }
      }
    }
    
    resource "yandex_lb_target_group" "lb_tg" {
      name = "reddit-app-targetgroup"
    
      target {
        address   = yandex_compute_instance.app.network_interface.0.ip_address
        subnet_id = var.subnet_id
      }
Выходные переменные в **output.tf**:

    output "external_ip_address_app" {
      value = yandex_compute_instance.app.network_interface.0.nat_ip_address
    }
    output "external_ip_address_lb" {
      value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
    }

### Задание с ** №2
Добавьте в код еще один terraform ресурс для нового инстанса приложения, например  reddit-app2, добавьте его в балансировщик и проверьте, что при остановке на одном из инстансов приложения (например  systemctl stop puma),  приложение продолжает быть доступным по адресу балансировщика; Добавьте в output переменные адрес второго инстанса; Какие проблемы вы видите в такой конфигурации приложения?
Сперва добавляем дополнительный ресурс в **main.tf**:

    terrraform {
      required_providers {
        yandex = {
          source = "yandex-cloud/yandex"
        }
      }
      required_version = ">= 0.13"
    }
    
    // Configure the Yandex.Cloud provider
    
    provider "yandex" {
      service_account_key_file = var.service_account_key_file
      cloud_id                 = var.cloud_id
      folder_id                = var.folder_id
      zone                     = var.zone
    }
    
    // Create a new instance
    
    resource "yandex_compute_instance" "app" {
      name = "reddit-app"
    
      resources {
        cores  = 2
        memory = 2
      }
    
      boot_disk {
        initialize_params {
          image_id = var.image_id
        }
      }
    
      network_interface {
        subnet_id = var.subnet_id
        nat       = true
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
    
      provisioner "file" {
        source      = "/home/Leppard741_infra/terraform/files/puma.service"
        destination = "/tmp/puma.service"
      }
      provisioner "remote-exec" {
        script = "/home/Leppard741_infra/terraform/files/deploy.sh"
      }
    }
    
    resource "yandex_compute_instance" "app2" {
      name = "reddit-app2"
    
      resources { 
        cores  = 2
        memory = 2
      }
    
      boot_disk {
        initialize_params {
          image_id = var.image_id
        }
      }
    
      network_interface {
        subnet_id = var.subnet_id
        nat       = true
      }
    
      metadata = {
        ssh-keys = "ubuntu:${file(var.public_key_path)}"
      }
    
      connection {
        type        = "ssh"
        host        = yandex_compute_instance.app2.network_interface.0.nat_ip_address
        user        = "ubuntu"
        agent       = false
        private_key = file(var.private_key_path)
      }
    
      provisioner "file" {
        source      = "/home/Leppard741_infra/terraform/files/puma.service"
        destination = "/tmp/puma.service"
      }
      provisioner "remote-exec" {
        script = "/home/Leppard741_infra/terraform/files/deploy.sh"
      }
    }
Добавляем дополнительный таргет в **lb.tf**:

    resource "yandex_lb_network_load_balancer" "lb" {
      name ="my-loadbalancer"
    
      listener {
        name        = "my-listener"
        port        = 80
        target_port = 9292
        protocol    = "tcp"
        external_address_spec {
          ip_version = "ipv4"
        }
      }
    
      attached_target_group {
        target_group_id = yandex_lb_target_group.lb_tg.id
        healthcheck {
          name = "http"
          http_options {
            port = 9292
          }
        }
      }
    }
    
    resource "yandex_lb_target_group" "lb_tg" {
      name = "reddit-app-targetgroup"
    
      target {
        address   = yandex_compute_instance.app.network_interface.0.ip_address
        subnet_id = var.subnet_id
      }
      target {
        address   = yandex_compute_instance.app2.network_interface.0.ip_address
        subnet_id = var.subnet_id
      }
    }
Ну и выходные переменные **output.tf**:

    output "external_ip_address_app" {
      value = yandex_compute_instance.app.network_interface.0.nat_ip_address
    }
    output "external_ip_address_app2" {
      value = yandex_compute_instance.app2.network_interface.0.nat_ip_address
    }
    output "external_ip_address_lb" {
      value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
    }
 Минусы такого подхода в избыточности кода, большее количество времени на инициализацию, разные базы данных.
 ### Задание с ** №3
Удалите описание  reddit-app2  и попробуйте подход с заданием количества инстансов через параметр ресурса  count. Переменная count должна задаваться в параметрах и по умолчанию равна 1.

Первым делом убираем упоминания о создании второго инстанса в **main.tf lb.tf output.tf**. После добавляем переменную в **terraform.tfvars** и описание в **variables.tf** с указанием default:

**terraform.tfvars**
 

       app_servers_count = 2

  **variables.tf**

      variable "app_servers_count" {
      description = "app_servers_count"
      default     = 1
    }
Далее вносим изменения в main.tf (параметры name и count - нумерация в названии и количство создаваемых инстансов)

    terraform {
      required_providers {
        yandex = {
          source = "yandex-cloud/yandex"
        }
      }
      required_version = ">= 0.13"
    }
    
    // Configure the Yandex.Cloud provider
    
    provider "yandex" {
      service_account_key_file = var.service_account_key_file
      cloud_id                 = var.cloud_id
      folder_id                = var.folder_id
      zone                     = var.zone
    }
    
    // Create a new instance
    
    resource "yandex_compute_instance" "app" {
      name  = "reddit-app-${count.index}"
      count = var.app_servers_count
      zone = var.zone
    
      resources {
        cores  = 2
        memory = 2
      }
    
      boot_disk {
        initialize_params {
          image_id = var.image_id
        }
      }
    
      network_interface {
        subnet_id = var.subnet_id
        nat       = true
      }
    
      metadata = {
        ssh-keys = "ubuntu:${file(var.public_key_path)}"
      }
    
      connection {
        type        = "ssh"
        host        = self.network_interface.0.nat_ip_address
        user        = "ubuntu"
        agent       = false
        private_key = file(var.private_key_path)
      }
    
      provisioner "file" {
        source      = "/home/Leppard741_infra/terraform/files/puma.service"
        destination = "/tmp/puma.service"
      }
      provisioner "remote-exec" {
        script = "/home/Leppard741_infra/terraform/files/deploy.sh"
      } 
    }
      
Добавляем динамическую группу в **lb.tf**:
resource "yandex_lb_network_load_balancer" "lb" {
  name ="my-loadbalancer"

      listener {
        name        = "my-listener"
        port        = 80
        target_port = 9292
        protocol    = "tcp"
        external_address_spec {
          ip_version = "ipv4"
        }
      }
    
      attached_target_group {
        target_group_id = yandex_lb_target_group.lb_tg.id
        healthcheck {
          name = "http"
          http_options {
            port = 9292
          }
        }
      }
    }
    
    resource "yandex_lb_target_group" "lb_tg" {
      name = "reddit-app-targetgroup"
      dynamic "target" {
        for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
        content {
          address   = target.value
          subnet_id = var.subnet_id
        }
      }
    }
Выходные переменные **outputs.tf**:

    output "external_ip_address_app" {
      value = [for ip in yandex_compute_instance.app.*.network_interface.0.nat_ip_address : ip]
    }
    output "external_ip_address_lb" {
      value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
    }
В итоге получаем более комплексный подход в создании одинаковых инстансов в связке load balancer.

