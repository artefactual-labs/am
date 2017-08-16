### Requirements

Ansible, docker-py, Docker, Docker Compose, git, make.

### Installation

These are the command you need to run when starting from scratch:

    $ ansible-playbook ../playbooks/download-sources.yml
    $ make create-volumes
    $ docker-compose build
    $ docker-compose up -d
    $ make bootstrap
    $ make restart-am-services

### Web UIs

- Archivematica Dashboard: http://127.0.0.1:62080/
- Archivematica Storage Service: http://127.0.0.1:62081/

### Ports

| Service                                 | Container port | Host port   |
| --------------------------------------- | -------------- | ----------- |
| mysql                                   | `tcp/3306`     | `tcp/62001` |
| elasticsearch                           | `tcp/9200`     | `tcp/62002` |
| redis                                   | `tcp/6379`     | `tcp/62003` |
| gearman                                 | `tcp/4730`     | `tcp/62004` |
| fits                                    | `tcp/2113`     | `tcp/62005` |
| clamavd                                 | `tcp/3310`     | `tcp/62006` |
| nginx » archivematica-dashboard         | `tcp/80`       | `tcp/62080` |
| nginx » archivematica-storage-service   | `tcp/8000`     | `tcp/62081` |
