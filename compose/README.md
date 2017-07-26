### Requirements

Ansible, docker-py, Docker, Docker Compose, git, make.

### Installation

These are the command you need to run when starting from scratch:

    $ ansible-playbook ../playbooks/download-sources.yml
    $ make create-volumes
    $ docker-compose build
    $ make bootstrap
    $ make restart-services

### Web interfaces

    - Archivematica Dashboard: http://127.0.0.1:62080/
    - Archivematica Storage Service: http://127.0.0.1:62081/

### Ports

- `62001`: mysql (`tcp/3306`)
- `62002`: elasticsearch (`tcp/9200`)
- `62003`: redis (`tcp/6379`)
- `62004`: gearman (`tcp/4730`)
- `62005`: fits (`tcp/2113`)
- `62006`: clamavd (`tcp/3310`)
- `62080`: nginx (`tcp/80`) » proxy to `archivematica-dashboard`
- `62081`: nginx (`tcp/8000`) » proxy to `archivematica-storage-service`
