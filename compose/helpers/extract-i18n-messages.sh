#!/usr/bin/env bash -x

set -o errexit
set -o pipefail
set -o nounset

__current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__compose_dir="$(cd "$(dirname "${__current_dir}")" && pwd)"
__root_dir="$(cd "$(dirname "${__compose_dir}")" && pwd)"

cd ${__compose_dir}

function dashboard::manage {
	docker-compose run \
		--rm --no-deps \
		--workdir=/src/dashboard/src \
		--entrypoint=/src/dashboard/src/manage.py \
			archivematica-dashboard "$@"
}

function storage::manage {
	docker-compose run \
		--rm --no-deps \
		--workdir=/src/storage_service \
		--entrypoint=/src/storage_service/manage.py \
			archivematica-storage-service "$@"
}

echo "Dashboard: extracting messages..."
dashboard::manage makemessages --all --domain django
dashboard::manage makemessages --all --domain djangojs --ignore build/*

(cd ${__root_dir}/src/archivematica && git status -s)

echo "Storage Service: extracting messages..."
storage::manage makemessages --all --domain django
storage::manage makemessages --all --domain djangojs

(cd ${__root_dir}/src/archivematica-storage-service && git status -s)

# Not ready yet:
# - transfer-browser
# - appraisal-tab
# - fpr-admin
