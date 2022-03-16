FROM debian:stable-slim

ARG BINDIR=/usr/bin

ARG KUBECTL_VERSION="v1.22.7" # https://kubernetes.io/releases/
ARG HELM_VERSION="v3.8.1" # https://github.com/helm/helm/releases
ARG HELMFILE_VERSION="v0.143.1" # https://github.com/roboll/helmfile/releases
ARG TERRAFORM_VERSION="1.1.7" https://github.com/hashicorp/terraform/releases
ARG TERRAGRUNT_VERSION="v0.36.3" # https://github.com/gruntwork-io/terragrunt/releases
ARG HELM_PLUGIN_VERSION_SECRETS="v3.12.0" # https://github.com/jkroepke/helm-secrets/releases
ARG HELM_PLUGIN_VERSION_GIT="0.11.1" # https://github.com/aslafy-z/helm-git/releases
ARG HELM_PLUGIN_VERSION_DIFF="3.4.2" # https://github.com/databus23/helm-diff/releases
ARG HELM_PLUGIN_VERSION_ENV="0.1.0" # https://github.com/adamreese/helm-env
ARG VELERO_VERSION="v1.8.1" # https://github.com/vmware-tanzu/velero/releases
ARG AWS_IAM_AUTHENTICATOR_VERSION="1.21.2/2021-07-05" # https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html

RUN apt update -y \
  && apt install -y sudo git openssh-client make openssl curl jq tar gzip unzip bash gnupg ca-certificates parallel \
  && curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
  && echo "deb [arch=amd64] https://download.docker.com/linux/debian buster stable" > /etc/apt/sources.list.d/docker.list \
  && curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg \
  && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ buster main" > /etc/apt/sources.list.d/azure.list \
  && curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/Release.key | apt-key add - \
  && echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_10/ /" \
   > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list \
  && apt update -y && apt install -y azure-cli docker-ce-cli skopeo \
   && curl -Lso- "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" | tar -xvz --strip-components=1 -C $BINDIR linux-amd64/helm \
  && curl -Lso- "https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz" | tar -xvz --strip-components=1  -C $BINDIR velero-${VELERO_VERSION}-linux-amd64/velero \
  && curl -Lso $BINDIR/kubectl "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
  && curl -Lso $BINDIR/helmfile "https://github.com/roboll/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_linux_amd64" \
  && curl -Lso- "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
  | gunzip -c > $BINDIR/terraform \
  && curl -Lso $BINDIR/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64" \
  && curl -Lso $BINDIR/aws-iam-authenticator "https://amazon-eks.s3-us-west-2.amazonaws.com/${AWS_IAM_AUTHENTICATOR_VERSION}/bin/linux/amd64/aws-iam-authenticator" \
  && curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp \
  && sudo mv /tmp/eksctl $BINDIR/ \
  && chmod 755 \
      $BINDIR/eksctl \
      $BINDIR/aws-iam-authenticator \
      $BINDIR/kubectl \
      $BINDIR/helmfile \
      $BINDIR/velero \
      $BINDIR/terraform \
      $BINDIR/terragrunt \
# Install helm plugins
  && helm plugin install https://github.com/jkroepke/helm-secrets --version ${HELM_PLUGIN_VERSION_SECRETS} \
  && helm plugin install https://github.com/aslafy-z/helm-git --version ${HELM_PLUGIN_VERSION_GIT} \
  && helm plugin install https://github.com/databus23/helm-diff --version ${HELM_PLUGIN_VERSION_DIFF} \
  && helm plugin install https://github.com/adamreese/helm-env --version ${HELM_PLUGIN_VERSION_ENV} \
# Install awscli v2
  && curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip \
  && unzip awscliv2.zip \
  && aws/install --install-dir /usr/local/aws-cli --bin-dir $BINDIR \
# Clean up some garbage
  && rm -rf /root/.cache \
     /tmp/* \
     /var/cache/apt/* \
     awscliv2.zip aws \
     /usr/local/aws-cli/v2/*/dist/aws_completer \
     /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
     /usr/local/aws-cli/v2/*/dist/awscli/examples
