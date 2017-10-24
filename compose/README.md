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

It is beyond the scope of this document to explain how these dependencies are
installed in your computer. If you're using Ubuntu 16.04 the following commands
may work:

    $ sudo apt update
    $ sudo apt install -y build-essential python-dev git
    $ sudo pip install -U ansible docker-compose

And install Docker CE following [https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/](these instructions).

## Installation

These are the command you need to run when starting from scratch:

    $ git submodule update --init --recursive
    $ make create-volumes
    $ docker-compose up -d --build
    $ make bootstrap
    $ make restart-am-services

`make create-volumes` creates two external volumes. They're heavily used in our
containers but they are provided in the host machine:

- `/tmp/am-pipeline-data` - the shared directory.
- `/tmp/ss-location-data` - the transfer source location.

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

If you've added new dependencies or changes the `Dockerfile` you should also
add the `--build` argument to the previous command in order to ensure that the
container is using the newest image, e.g.:

    $ docker-compose up -d --force-recreate --build --no-deps archivematica-mcp-server

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

## Resetting the environment

In many cases, as a tester or a developer, you want to restart all the
containers at once and make sure the latest version of the images are built.
But also, you don't want to lose your data like the search index or the
database. If this is case, run the following command:

    $ docker-compose up -d --force-recreate --build

Additionally you may want to delete all the deta including the stuff in the
external volumes:

    $ make flush

Both snippets can be combined or used separately.

## Cleaning up

The most effective way is:

    $ docker-compose down --volumes

It doesn't delete the external volumes described in the
[Installation](#installation) section of this document. You have to delete the
volumes manually with:

    $ docker volume rm am-pipeline-data
    $ docker volume rm ss-location-data

Optionally you may also want to delete the directories:

    $ rm -rf /tmp/am-pipeline-data /tmp/ss-location-data
