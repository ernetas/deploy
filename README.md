This is a Docker image for use when deploying. The aim is to focus on Docker tools that will be needed to deploy on Kubernetes. Everything else should probably go to Dockerfile (use multistage builds if needed) or other images should be created.

[Docker Hub](https://hub.docker.com/repository/docker/ernestas/deploy)
[Github Container Registry](https://github.com/ernetas/deploy/pkgs/container/deploy)

Includes:
- Terraform
- Terragrunt
- AWS IAM authenticator
- AWS CLI v2
- Azure CLI
- kubectl
- helm with a couple of plugins
- helmfile
- velero
