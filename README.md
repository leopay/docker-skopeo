# Skopeo on Alpine Linux
[![](https://images.microbadger.com/badges/image/bdwyertech/skopeo.svg)](https://microbadger.com/images/bdwyertech/skopeo)
[![](https://images.microbadger.com/badges/version/bdwyertech/skopeo.svg)](https://microbadger.com/images/bdwyertech/skopeo)

This is a container designed for using Skopeo within a CI pipeline.

It contains [a custom helper utility](helper-utility/README.md) to provision `~/.docker/config.json`

It also contains [an ECR Scanner utility](ecr-scanner/README.md) which can be leveraged in a pipeline as a pre-promotion check.
