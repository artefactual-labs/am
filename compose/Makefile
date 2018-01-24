
# Paths for Docker named volumes
AM_PIPELINE_DATA ?= /tmp/am-pipeline-data
SS_LOCATION_DATA ?= /tmp/ss-location-data


create-volumes:  ## Create external data volumes.
	mkdir -p ${AM_PIPELINE_DATA}
	docker volume create \
		--opt type=none \
		--opt o=bind \
		--opt device=$(AM_PIPELINE_DATA) \
			am-pipeline-data
	mkdir -p ${SS_LOCATION_DATA}
	docker volume create \
		--opt type=none \
		--opt o=bind \
		--opt device=$(SS_LOCATION_DATA) \
			ss-location-data

bootstrap: bootstrap-storage-service bootstrap-dashboard-db bootstrap-dashboard-frontend  ## Full bootstrap.

bootstrap-storage-service:  ## Boostrap Storage Service (new database).
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "\
		DROP DATABASE IF EXISTS SS; \
		CREATE DATABASE SS; \
		GRANT ALL ON SS.* TO 'archivematica'@'%' IDENTIFIED BY 'demo';"
	docker-compose run \
		--rm \
		--entrypoint /src/storage_service/manage.py \
			archivematica-storage-service \
				migrate --noinput
	docker-compose run \
		--rm \
		--entrypoint /src/storage_service/manage.py \
			archivematica-storage-service \
				create_user \
					--username="test" \
					--password="test" \
					--email="test@test.com" \
					--api-key="test"
	# SS needs to be restarted so the local space is created.
	# See #303 (https://git.io/vNKlM) for more details.
	docker-compose restart archivematica-storage-service

makemigrations-ss:
	docker-compose run \
		--rm \
		--entrypoint /src/storage_service/manage.py \
			archivematica-storage-service \
				makemigrations

bootstrap-dashboard-db:  ## Bootstrap Dashboard (new database).
	docker-compose exec mysql mysql -hlocalhost -uroot -p12345 -e "\
		DROP DATABASE IF EXISTS MCP; \
		CREATE DATABASE MCP; \
		GRANT ALL ON MCP.* TO 'archivematica'@'%' IDENTIFIED BY 'demo';"
	docker-compose run \
		--rm \
		--entrypoint /src/dashboard/src/manage.py \
			archivematica-dashboard \
				migrate --noinput
	docker-compose run \
		--rm \
		--entrypoint /src/dashboard/src/manage.py \
			archivematica-dashboard \
				install \
					--username="test" \
					--password="test" \
					--email="test@test.com" \
					--org-name="test" \
					--org-id="test" \
					--api-key="test" \
					--ss-url="http://archivematica-storage-service:8000" \
					--ss-user="test" \
					--ss-api-key="test"

bootstrap-dashboard-frontend:  ## Build front-end assets.
	docker-compose run --rm --no-deps \
		--user root \
		--entrypoint npm \
		--workdir /src/dashboard/frontend/transfer-browser \
			archivematica-dashboard \
				install --unsafe-perm
	docker-compose run --rm --no-deps \
		--user root \
		--entrypoint npm \
		--workdir /src/dashboard/frontend/appraisal-tab \
			archivematica-dashboard \
				install --unsafe-perm

restart-am-services:  ## Restart Archivematica services: MCPServer, MCPClient, Dashboard and Storage Service.
	docker-compose restart archivematica-mcp-server
	docker-compose restart archivematica-mcp-client
	docker-compose restart archivematica-dashboard
	docker-compose restart archivematica-storage-service

db:  ## Connect to the MySQL server using the CLI.
	mysql -h127.0.0.1 --port=62001 -uroot -p12345

flush: flush-shared-dir flush-elasticsearch-indices bootstrap restart-am-services  ## Delete ALL user data.

flush-shared-dir-mcp-configs:  ## Delete processing configurations - it restarts MCPServer.
	rm -f ${AM_PIPELINE_DATA}/sharedMicroServiceTasksConfigs/processingMCPConfigs/defaultProcessingMCP.xml
	rm -f ${AM_PIPELINE_DATA}/sharedMicroServiceTasksConfigs/processingMCPConfigs/automatedProcessingMCP.xml
	docker-compose restart archivematica-mcp-server

flush-shared-dir:  ## Delete contents of the shared directory data volume.
	rm -rf ${AM_PIPELINE_DATA}/*

flush-elasticsearch-indices:  ## Deletes Elasticsearch indices.
	docker-compose exec archivematica-mcp-client curl -XDELETE "http://elasticsearch:9200/aips,transfers"

test-all: test-mcp-server test-mcp-client test-dashboard test-storage-service  ## Run all tests.

test-mcp-server:  ## Run MCPServer tests.
	docker-compose run --workdir /src/MCPServer --rm --user=root --entrypoint=py.test archivematica-mcp-server

test-mcp-client:  ## Run MCPClient tests.
	docker-compose run --workdir /src/MCPClient --rm --user=root --entrypoint=py.test archivematica-mcp-client

test-dashboard:  ## Run Dashboard tests.
	docker-compose run --workdir /src/dashboard --rm --user=root --entrypoint=py.test archivematica-dashboard

test-storage-service:  ## Run Storage Service tests.
	docker-compose run --workdir /src --rm --user=root --no-deps --entrypoint py.test -e "DJANGO_SETTINGS_MODULE=storage_service.settings.test" archivematica-storage-service

test-at-up:
	docker-compose -f docker-compose.yml -f docker-compose.acceptance-tests.yml up -d

test-at-check: test-at-up  ## Make sure that both Firefox and Chrome are working.
	docker-compose -f docker-compose.yml -f docker-compose.acceptance-tests.yml run --rm --no-deps archivematica-acceptance-tests simplehubtest

test-at-run: test-at-up  ## Run the acceptance tests.
	docker-compose -f docker-compose.yml -f docker-compose.acceptance-tests.yml run --rm --no-deps archivematica-acceptance-tests all

test-at-run-firefox: test-at-up  ## Run the tests using just Firefox.
	docker-compose -f docker-compose.yml -f docker-compose.acceptance-tests.yml run --rm --no-deps archivematica-acceptance-tests firefox

test-at-run-chrome: test-at-up  ## Run the tests using just Chrome.
	docker-compose -f docker-compose.yml -f docker-compose.acceptance-tests.yml run --rm --no-deps archivematica-acceptance-tests chrome

test-at-restarted:  ## Ensure that all the containers are restarted.
	docker-compose -f docker-compose.yml -f docker-compose.acceptance-tests.yml up -d --force-recreate --no-deps selenium-hub selenium-firefox selenium-chrome archivematica-acceptance-tests

test-at-rebuilt:  ## Ensure that all the containers are rebuilt and restarted.
	docker-compose -f docker-compose.yml -f docker-compose.acceptance-tests.yml up -d --build --force-recreate --no-deps selenium-hub selenium-firefox selenium-chrome archivematica-acceptance-tests

test-at-logs:  ## Watch the logs generated by the containers for debugging purposes.
	docker-compose -f docker-compose.yml -f docker-compose.acceptance-tests.yml logs -f selenium-hub selenium-firefox selenium-chrome archivematica-acceptance-tests

test-at-stop:  ## Stop services - because browsers are not particularly lightweight.
	docker-compose -f docker-compose.yml -f docker-compose.acceptance-tests.yml stop selenium-hub selenium-firefox selenium-chrome archivematica-acceptance-tests

help:  ## Print this help message.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
