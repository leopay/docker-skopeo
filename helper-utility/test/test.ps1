# Test.ps1

docker pull bdwyertech/skopeo:latest
docker run -it --rm --env-file .env bdwyertech/skopeo:latest
