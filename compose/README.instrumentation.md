
Instrumentation
===============

This Prometheus-Grafana instrumentation solution is based on [Dockprom](https://github.com/stefanprodan/dockprom).

Usage
=====

To build instrumentation containers, please run:

	$ make instrumentation

To rebuild instrumentation containers:

        $ make instrumentation-rebuild

To restart instrumentation containers:

        $ make restart-instrumentation 

Authentication variables
========================

These authentication containers use a common user/password. They are defined in
the following variables:

* `INSTRUMENTATION_ADMIN_USER`
* `INSTRUMENTATION_ADMIN_PASSWORD`

Default values: admin:admin1234

These variables can be changed at compose/.env file.

Service URLS
============

Assuming that `host.example.com` is a docker host valid public address,
the following instrumentation URLs are available:

Instrumentation containers stats:

* `http://host.example.com:3000/dashboard/db/monitor-services?refresh=10s&orgId=1`

Docker Host stats:

* `http://host.example.com:3000/dashboard/db/docker-host?refresh=10s&orgId=1`

RDSS containers stats:

* `http://host.example.com:3000/dashboard/db/docker-containers?refresh=10s&orgId=1`

MCPServer stats:

* `http://host.example.com:3000/dashboard/db/archivematica-mcpserver-dashboard?refresh=10s&orgId=1`
