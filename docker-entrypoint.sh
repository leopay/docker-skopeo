#!/bin/sh -e
# Magic to Provision the Container
# Brian Dwyer - Intelligent Digital Services

# Workaround for GitLab ENTRYPOINT double execution (issue: 1380)
if [ ! -e '/tmp/.gitlab-runner.lock' ]; then
	touch /tmp/.gitlab-runner.lock
	# Docker Configuration Helper Utility
	helper-utility
fi

# Passthrough
exec "$@"
