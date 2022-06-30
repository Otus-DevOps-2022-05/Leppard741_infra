# Leppard741_infra
Leppard741 Infra repository OTUS DevOps 2022
## Instance details
bastion_IP = 51.250.88.101
someinternalhost_IP = 10.128.0.4
## YC deploy app details
testapp_IP = 51.250.87.119
testapp_port = 9292
## Packer homework

###1) Параметризируйте созданный вами шаблон.

1.1) Необходимо создать файл variables.json и задать значения переменным в качестве примера показан и закоммичен variables.json.examples:

{
  "folder_id": "iddqd",
  "source_image_family": "iddt",
  "key_file": "./idkfa.json",
  "ssh_user": "doomslayer"
}

1.2) После этого вносим изменения в ubuntu16.json

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

1.3) Далее для сборки образа запускаем packer build -var-file=variables.json ubuntu16.json после чего будет создан образ и присвоен id
 
###2) Построение bake-образа

2.1) Была добавлена переменная в variables в части image_family и описаны провиженеры с добавлением юнита и установкой reddit с его зависимостями 

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

###3) Автоматизация создания ВМ

3.1) После сборки образа с предустановленным и готовым к работе reddit получает id этого образа и собираем скрипт для сборки инстанса через YC
yc-reddit-bake.sh:

#!/bin/sh

#!/bin/sh

yc compute instance create \
 --name reddit-app-bake \
 --hostname reddit-app-bake \
 --memory=4 \
 --create-boot-disk image-id=fd8qpdnpksdublj72a9g,size=10GB \
 --network-interface subnet-name=net-1-ru-central1-b,nat-ip-version=ipv4 \
 --metadata serial-port-enable=1 \
 --ssh-key ~/.ssh/appuser.pub \
 --zone ru-central1-b

3.2) На выходе получаем инстанс с работающим приложением reddit
