# Archivematica on Docker Compose

- [Audience](#audience)
- [Requirements](#requirements)
- [Installation](#installation)
- [Web UIs](#web-uis)
- [Source code auto-reloading](#source-code-auto-reloading)
- [Ports](#ports)
- [Cleaning up](#cleaning-up)

## Audience

This Archivematica environment is based on Docker Compose and it is specifically
**designed for developers**. Compose can be used in production but that is
beyond the scope of this recipe.

## Requirements

Ansible, docker-py, Docker, Docker Compose, git, make.

## Installation

These are the command you need to run when starting from scratch:

    $ ansible-playbook ../playbooks/download-sources.yml
    $ make create-volumes
    $ docker-compose up -d --build
    $ make bootstrap
    $ make restart-am-services

## Web UIs

- Archivematica Dashboard: http://127.0.0.1:62080/
- Archivematica Storage Service: http://127.0.0.1:62081/

## Source code auto-reloading

Dashboard and Storage Service are both served by Gunicorn. We set up Gunicorn
with the [reload](http://docs.gunicorn.org/en/stable/settings.html#reload)
setting enabled meaning that the Gunicorn workers will be restarted as soon as
code changes.

Other components in the stack like the `MCPServer` don't offer this option and
they need to be restarted manually, e.g.:

    $ docker-compose up -d --force-recreate --no-deps archivematica-mcp-server

## Ports

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

## Cleaning up

The most effective way is:

    $ docker-compose down --volumes

But most of the times you don't want to do that unless you want to delete all
the things. If you just need to clean up the data but rely on the same
containers you can run the following instead:

    $ make flush

If you want to try new code, run:

    $ docker-compose up -d --build --force-recreate
    $ make flush
