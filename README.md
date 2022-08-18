# Leppard741_infra
Leppard741 Infra repository OTUS DevOps 2022

<details><summary>Instance details</summary> 
bastion_IP = 51.250.88.101
someinternalhost_IP = 10.128.0.4
</details>

<details><summary>YC deploy app details</summary> 
testapp_IP = 51.250.87.119
testapp_port = 9292
</details>

<details><summary>Packer</summary>

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
</details>

<details><summary>Terraform 1</summary>

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

</details>

<details><summary>Terraform 2</summary>

**Дополнительное задание №1** 
Настройка хранения стейт файла в удаленном бекенде (remote  
backends) для окружений  stage  и  prod


Создаём бакет для хранения состояния `terraform` **(.tfstate)**, перед созданием бакета был создан создан сервисный аккаунт, присвоена роль и сгенерирован ключ. После выполнения команды `yc iam access-key list --service-account-name ****` необходимо сохранить access и secret key после чего задать их в качетсве отдельных переменных.
Создание бакета выведено отдельным модулем

    resource "yandex_storage_bucket" "backend-s3" {
      access_key = var.access_key
      secret_key = var.secret_key
      bucket = "backend-s3"
    }

Для обоих сред `stage` и `prod` создаём файл с описанием бэкенда (backend.tf):

    terraform {
      backend "s3" {
        endpoint   = "storage.yandexcloud.net"
        bucket     = "backend-s3"
        region     = "ru-central1"
        key        = "stage.tfstate"
        access_key = "место для ключа"
        secret_key = "место для секрета"
    
        skip_region_validation      = true
        skip_credentials_validation = true
      }
    }

Удаляем файлы состояния `.tfstate`после чего проводим инициализацию `terraform init` и применение изменений `terraform apply`. После создания инстансов видно, что файл `.tfstate` не появился так как теперь он храниться хранится в бакете `(Object Storage)`. При одновременном выполнении заданий из разных папок появлялась ошибка создания ресурса с одинаковым именем.

----------

**Дополнительное задание №2**

Добавить необходимые provisioner в модули для деплоя и работы приложения. Файлы, используемые в provisioner, должны находится в директории модуля

В папке модуля `app` создадим директорию `files`, переносим в неее ранее созданные `puma.service` `deploy.sh`. 
В `main.tf` модуля возвращаем секции `connection` и `provisioner` .

    ...
      connection {
        type        = "ssh"
        host        = yandex_compute_instance.app.network_interface.0.nat_ip_address
        user        = "ubuntu"
        agent       = false
        private_key = file(var.private_key_path)
      }
    
       provisioner "file" {
        content     = templatefile("/home/Leppard741_infra/terraform/modules/app/files/puma.ser>
        destination = "/tmp/puma.service"
      }
      provisioner "remote-exec" {
        script = "/home/Leppard741_infra/terraform/modules/app/files/deploy.sh"
      }
    ...

В файл `variables.tf` добавим переменную указывающую на закрытый  ключ и внесем изменения в `main.tf` окружения `stage`:

    ...
    module "app" {
      source            = "../modules/app"
      public_key_path   = var.public_key_path
      private_key_path   = var.private_key_path
      app_disk_image_id = var.app_disk_image_id
      subnet_id         = var.subnet_id
      zone              = var.zone
      environment       = var.environment
    }
    ...

Применяем конфигурацию `terraform apply`, переходим в браузер по адресу app инстанса, порт 9292 доступен однако нет связи с mongodb так как она теперь на отдельном инстансе.
Для того что бы это исправить создаем .tftpl файл со следущим содержимым вместо ранее используемого юнит файла  модуля `app`

    [Unit]
    Description=Puma HTTP Server
    After=network.target
    
    [Service]
    Type=simple
    User=ubuntu
    WorkingDirectory=/home/ubuntu/reddit
    ExecStart=/bin/bash -lc 'puma'
    Restart=always
    Environment=DATABASE_URL=${MONGODB_DATABASE_URL}
    
    [Install]
    WantedBy=multi-user.target

Добавляем переменную в `variables.tf` модуля `app`:

    variable "database_ip" {
      description = "IP address of Mongodb server"
    }

Изменим секцию provisioner в `main.tf` модуля `app`:

       provisioner "file" {
        content     = templatefile("/home/Leppard741_infra/terraform/modules/app/files/puma.ser>
        destination = "/tmp/puma.service"
      }

Добавим `database_ip` в  `main.tf` окружения `stage`:

    module "app" {
      source            = "../modules/app"
      public_key_path   = var.public_key_path
      private_key_path  = var.private_key_path
      app_disk_image_id = var.app_disk_image_id
      subnet_id         = var.subnet_id
      zone              = var.zone
      environment       = var.environment
      database_ip       = module.db.external_ip_address_db
    }

Далее для того что бы mongodb прослушивала все доступные интерфейсы нужно изменить значение "bind_ip = 127.0.0.1" на "bind_ip = 0.0.0.0". для этого сделаем скрипт и привяжем его к провиженеру + добавление переменной закрытого ключа в секции `connection` .
Тело скрипта:

    #!/bin/sh
    sudo sed -i s/127.0.0.1/0.0.0.0/ /etc/mongodb.conf
    sudo systemctl restart mongodb

Провиженер `main.tf` модуля `db`:

       provisioner "remote-exec" {
        script = "/home/Leppard741_infra/terraform/modules/db/files/config_mongodb.sh"
      }
После чего выполняем terraform apply и получаем нужный результат = рабочее приложение с выведенной отдельно mongodb.

</details>

<details><summary>Ansible 1</summary>

**Задание 1** 
Теперь выполните  `ansible  app  -m  command  -a  'rm  -rf  ~/reddit'`  
и проверьте еще раз выполнение плейбука. Что изменилось и почему?

**Решение** - Команда удалит директорию и вложенные файлы репозитория приложения. После запуска `ansible-playbook clone.yaml` репозиторий будет заново клонирован что отразиться в статусе выполнения плейбука.

----------

**Задание 2**
 Для описания инвентори Ansible использует форматы файлов INI и YAML. Также поддерживается формат JSON. При этом, Ansible поддерживает две различных схемы JSON-inventory: одна является прямым отображением YAML-формата (можно сделать через конвертер YAML <-> JSON), а другая используется для динамического inventory. С небольшими ухищрениями можно заставить Ansible использовать вторую схему и для статических JSON-файлов. Попробуем это сделать...

1.  Ознакомьтесь с [Динамическое инвентори в Ansible](https://nklya.medium.com/%D0%B4%D0%B8%D0%BD%D0%B0%D0%BC%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%BE%D0%B5-%D0%B8%D0%BD%D0%B2%D0%B5%D0%BD%D1%82%D0%BE%D1%80%D0%B8-%D0%B2-ansible-9ee880d540d6).
2.  Создайте файл inventory.json в формате, описанном в п.1 для нашей ya.cloud-инфраструктуры и скрипт для работы с ним.
3.  Добейтесь успешного выполнения команды ansible all -m ping и опишите шаги в README.
4.  Добавьте параметры в файл ansible.cfg для работы с инвентори в формате JSON.
5.  Если вы разобрались с отличиями схем JSON для динамического и статического инвентори, также добавьте описание в README

**Решение** - Динамическое инвентори - это скрипт, который получает информацию о хостах из какого-то источника и отдаёт её в формате JSON.

Содержимое **inventory.json** :

    {
        "all": {
            "children": {
                "app": {
                    "hosts": {
                        "appserver": {
                            "ansible_host": "62.84.114.91"
                        }
                    }
                },
                "db": {
                    "hosts": {
                        "dbserver": {
                            "ansible_host": "62.84.117.243"
                        }
                    }
                }
            }
        }
    }




Для работы динамического инвентори нужно вернуть список хостов и блок `_meta`, в котором указаны переменные хостов. 
В качестве примера создадим файл источник для скрипта динамического инвентори **inventory-src.json**:

    {
        "app": {
            "hosts": ["appserver"]
        },
        "db": {
            "hosts": ["dbserver"]
        },
        "_meta": {
            "hostvars": {
                "appserver": {
                    "ansible_host": "62.84.114.91"
                },
                "dbserver": {
                    "ansible_host": "62.84.117.243"
                }
            }
        }
    }

Далее создаем скрипт , который будет передавать ansible сформированный файл. 
Содержимое скрипта `dynamic-inventory.sh`:

    #!/bin/sh
    
    cat inventory-source.json

Проверяем работу "динамического" инвентори:

    # ansible -i ./dynamic-inventory.sh all -m ping
    dbserver | SUCCESS => {
        "ansible_facts": {
            "discovered_interpreter_python": "/usr/bin/python3"
        },
        "changed": false,
        "ping": "pong"
    }
    appserver | SUCCESS => {
        "ansible_facts": {
            "discovered_interpreter_python": "/usr/bin/python3"
        },
        "changed": false,
        "ping": "pong"
    }

Меняем конфигурацию `ansible.cfg`

    [defaults]
    inventory = ./dynamic-inventory.sh
    remote_user = ubuntu
    private_key_file = ~/.ssh/ubuntu
    host_key_checking = False
    retry_files_enabled = False

Проверяем работу

    # ansible all -m ping
    appserver | SUCCESS => {
        "ansible_facts": {
            "discovered_interpreter_python": "/usr/bin/python3"
        },
        "changed": false,
        "ping": "pong"
    }
    dbserver | SUCCESS => {
        "ansible_facts": {
            "discovered_interpreter_python": "/usr/bin/python3"
        },
        "changed": false,
        "ping": "pong"
    }
На выходе получаем скрипт для с динамическим инвентори.

</details>

<details><summary>Ansible 2</summary>


**Задание со ⭐** Ansible на текущий момент (07.2020) из коробки не умеет динамическую инвентаризацию в Yandex.Cloud. Нам нужно писать свои костыли, как в предыдущем ДЗ. Но если порыскать по репозиторию, то можно натолкнуться на вот [PR](https://github.com/ansible/ansible/pull/61722). Попробуйте использовать это решение для инвентаризации.

**Решение**  Клонируем себе ветку репозитория, плагин находится по следующему адресу: `community.general/plugins/inventory/yc_compute.py`, переносим его в директорию хранения плагинов ansible - 

    ~/.ansible/plugins/inventory
    
Для включения плагина, нужно добавить его в `ansible.cfg` и установить Yandex.SDK `pip3 install yandexcloud` :

Из описания к плагину видно что управление происходит через yml файл, создаем его:
`yc.yml`:

    plugin: yc_compute
    
    folders:
      - id***************
    
    auth_kind: serviceaccountfile
    
    service_account_file: "Путь до ключа"
    
    hostnames:
      - fqdn
    
    compose:
      ansible_host: network_interfaces[0].primary_v4_address.one_to_one_nat.address
    
    keyed_groups:
      - key: labels['group']
        prefix: ''
        separator: ''
        [defaults]
        inventory = ./yc.yml
        remote_user = ubuntu
        private_key_file = ~/.ssh/ubuntu
        host_key_checking = False
        retry_files_enabled = False
        
        [inventory]
        enable_plugins = yc_compute
Добавлем все изменения в `ansible.cfg`

    [defaults]
    inventory = ./yc.yml
    remote_user = ubuntu
    private_key_file = ~/.ssh/ubuntu
    host_key_checking = False
    retry_files_enabled = False
    
    [inventory]
    enable_plugins = yc_compute
Выдача от комманды `ansible-inventory --list` должна показать активные хосты YC

----------

**Самостоятельное задание**

1.  Заменить скрипты, используемые `packer` на плэйбуки `ansible`.
2.  Заменить скрипты в секциях `provisioners` файлов конфигурации `packer` на `ansible`.

**Решение** Содержимое плэйбука `packer_app.yml` :

    - name: Install base for application deploy
      hosts: all
      become: true
      tasks:
        - name: Install packages for app base
          apt:
            name: ['apt-transport-https', 'ca-certificates', 'ruby-full', 'ruby-bundler', 'build-essential', 'git']
            state: present
            update_cache: yes
          retries: 5
          delay: 20
    
        - name: Remove useless packages from the cache
          apt:
            autoclean: yes
    
        - name: Remove dependencies that are no longer required
          apt:
            autoremove: yes

Содержимое плэйбука`packer_db.yml`:

    - name: Install base for database server
      hosts: all
      become: true
      tasks:
        - name: Install mongodb
          apt:
            name: mongodb
            state: present
            update_cache: yes
          retries: 5
          delay: 20
    
        - name: Remove useless packages from the cache
          apt:
            autoclean: yes
    
        - name: Remove dependencies that are no longer required
          apt:
            autoremove: yes
    
        - name: Enable mongodb service
          systemd:
            name: mongodb
            enabled: yes

Заменим `provisioners` с `shell` на `ansible`. 

Содержимое `packer/app.json`:

    {
        "variables": {
            "mv_service_account_key_file": "",
            "mv_folder_id": "",
            "mv_source_image_family": ""
        },
        "builders": [
            {
                "type": "yandex",
                "service_account_key_file": "{{user `mv_service_account_key_file`}}",
                "folder_id": "{{user `mv_folder_id`}}",
                "source_image_family": "{{user `mv_source_image_family`}}",
                "image_name": "reddit-app-{{timestamp}}",
                "image_family": "reddit-app",
                "ssh_username": "ubuntu",
                "platform_id": "standard-v1",
                "use_ipv4_nat": "true"
            }
        ],
        "provisioners": [
            {
                "type": "ansible",
                "use_proxy": false,
                "playbook_file": "ansible/packer_app.yml"
            }
        ]
    }

Содержимое `packer/db.json`:

    {
        "variables": {
            "mv_service_account_key_file": "",
            "mv_folder_id": "",
            "mv_source_image_family": ""
        },
        "builders": [
            {
                "type": "yandex",
                "service_account_key_file": "{{user `mv_service_account_key_file`}}",
                "folder_id": "{{user `mv_folder_id`}}",
                "source_image_family": "{{user `mv_source_image_family`}}",
                "image_name": "reddit-db-{{timestamp}}",
                "image_family": "reddit-db",
                "ssh_username": "ubuntu",
                "platform_id": "standard-v1",
                "use_ipv4_nat": "true"
            }
        ],
        "provisioners": [
            {
                "type": "ansible",
                "use_proxy": false,
                "playbook_file": "ansible/packer_db.yml"
            }
        ]
    }

Командой `packer build -var-file=./packer/variables.json ./packer/app.json` и `packer build -var-file=./packer/variables.json ./packer/db.json` собираем образы и помощью полученных id образов собираем инстансы через terraform.

Проверяем работу инвентори на наличие инстансов `ansible-inventory --list`и выполняем   `ansible-playbook site.yml`после отработки сервис reddit будет доступен.

</details>
