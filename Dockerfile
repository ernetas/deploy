FROM debian:bullseye-slim

ARG BINDIR=/usr/bin

ARG KUBECTL_VERSION="v1.22.7" # https://kubernetes.io/releases/
ARG HELM_VERSION="v3.8.1" # https://github.com/helm/helm/releases
ARG HELMFILE_VERSION="v0.143.1" # https://github.com/roboll/helmfile/releases
ARG TERRAFORM_VERSION="1.1.7" https://github.com/hashicorp/terraform/releases
ARG TERRAGRUNT_VERSION="v0.36.6" # https://github.com/gruntwork-io/terragrunt/releases
ARG HELM_PLUGIN_VERSION_SECRETS="v3.12.0" # https://github.com/jkroepke/helm-secrets/releases
ARG HELM_PLUGIN_VERSION_GIT="0.11.1" # https://github.com/aslafy-z/helm-git/releases
ARG HELM_PLUGIN_VERSION_DIFF="3.4.2" # https://github.com/databus23/helm-diff/releases
ARG HELM_PLUGIN_VERSION_ENV="0.1.0" # https://github.com/adamreese/helm-env
ARG VELERO_VERSION="v1.8.1" # https://github.com/vmware-tanzu/velero/releases
ARG AWS_IAM_AUTHENTICATOR_VERSION="1.21.2/2021-07-05" # https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html

RUN cd /tmp \
  && apt-get update -y \
  && apt-get install -y \
    bash \
    ca-certificates \
    curl \
    git \
    gnupg \
    gpg \
    gzip \
    jq \
    make \
    openssh-client \
    openssl \
    perl \
    tar \
    unzip \
    wget \
  && gpg --keyserver keyserver.ubuntu.com --recv-keys "FB5DB77FD5C118B80511ADA8A6310ACC4672475C" \
  && echo "FB5DB77FD5C118B80511ADA8A6310ACC4672475C:6:" | gpg --import-ownertrust \
  && gpg --keyserver keyserver.ubuntu.com --recv-keys "711F28D510E1E0BCBD5F6BFE9436E80BFBA46909" \
  && echo "711F28D510E1E0BCBD5F6BFE9436E80BFBA46909:6:" | gpg --import-ownertrust \
  && curl -sSLo- https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
  && curl -sSLo- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ bullseye main" > /etc/apt/sources.list.d/azure.list \
  && curl -sSLo- https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_11/Release.key | gpg --dearmor -o /usr/share/keyrings/opensuse-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/opensuse-keyring.gpg] http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/Debian_11/ /" \
   > /etc/apt/sources.list.d/devel-kubic-libcontainers-stable.list \
  && apt-get update -y \
  && apt-get install -y \
    azure-cli \
    docker-ce-cli \
    skopeo \
  && curl -sSLo "/tmp/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz" "https://get.helm.sh/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz" \
  && curl -ssLo "/tmp/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz.sha256sum" "https://get.helm.sh/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz.sha256sum" \
  && curl -ssLo "/tmp/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz.asc" "https://github.com/helm/helm/releases/download/${HELM_VERSION}/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz.asc" \
  && curl -ssLo "/tmp/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz.sha256sum.asc" "https://github.com/helm/helm/releases/download/${HELM_VERSION}/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz.sha256sum.asc" \
  && gpg --verify "/tmp/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz.sha256sum.asc" "/tmp/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz.sha256sum" \
  && gpg --verify "/tmp/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz.asc" "/tmp/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz" \
  && shasum --ignore-missing -c "/tmp/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz.sha256sum" \
  && tar xf "/tmp/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz" --strip-components=1 -C $BINDIR linux-$(dpkg --print-architecture)/helm \
  && curl -sSLo "/tmp/velero-checksum" "https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/CHECKSUM" \
  && curl -sSLo "/tmp/velero-${VELERO_VERSION}-linux-$(dpkg --print-architecture).tar.gz" "https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-$(dpkg --print-architecture).tar.gz" \
  && shasum --ignore-missing -c /tmp/velero-checksum \
  && tar xf "/tmp/velero-${VELERO_VERSION}-linux-$(dpkg --print-architecture).tar.gz" --strip-components=1 -C $BINDIR "velero-${VELERO_VERSION}-linux-$(dpkg --print-architecture)/velero" \
  && curl -sSLo /tmp/kubectl.sha256 "https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/$(dpkg --print-architecture)/kubectl.sha256" \
  && curl -sSLo /tmp/kubectl "https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/$(dpkg --print-architecture)/kubectl" \
  && if [ "$(openssl sha1 -sha256 /tmp/kubectl | awk '{print $2}')" != "$(cat -s /tmp/kubectl.sha256)" ]; then echo "checksum mismatch"; openssl sha1 -sha256 /tmp/kubectl; cat /tmp/kubectl.sha256; exit 1; fi \
  && mv /tmp/kubectl ${BINDIR}/kubectl \
  && curl -sSLo $BINDIR/helmfile "https://github.com/roboll/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_linux_$(dpkg --print-architecture)" \
  && gpg --recv-keys "C874011F0AB405110D02105534365D9472D7468F" \
  && echo "C874011F0AB405110D02105534365D9472D7468F:6:" | gpg --import-ownertrust \
  && curl -sSLo "/tmp/terraform_${TERRAFORM_VERSION}_linux_$(dpkg --print-architecture).zip" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_$(dpkg --print-architecture).zip" \
  && curl -sSLo "/tmp/terraform_${TERRAFORM_VERSION}_SHA256SUMS" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
  && curl -sSLo "/tmp/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig" "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig" \
  && gpg --verify "/tmp/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig" "/tmp/terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
  && shasum --algorithm 256 --ignore-missing -c "/tmp/terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
  && gunzip -c "terraform_${TERRAFORM_VERSION}_linux_$(dpkg --print-architecture).zip" > $BINDIR/terraform \
  && curl -sSLo /tmp/terragrunt_linux_$(dpkg --print-architecture) "https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_$(dpkg --print-architecture)" \
  && curl -sSLo /tmp/SHA256SUMS "https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/SHA256SUMS" \
  && shasum --ignore-missing -c /tmp/SHA256SUMS \
  && mv /tmp/terragrunt_linux_$(dpkg --print-architecture) $BINDIR/terragrunt \
  && curl -sSLo /tmp/aws-iam-authenticator "https://amazon-eks.s3-us-west-2.amazonaws.com/${AWS_IAM_AUTHENTICATOR_VERSION}/bin/linux/$(dpkg --print-architecture)/aws-iam-authenticator" \
  && curl -sSLo /tmp/aws-iam-authenticator.sha256 "https://amazon-eks.s3.us-west-2.amazonaws.com/${AWS_IAM_AUTHENTICATOR_VERSION}/bin/linux/$(dpkg --print-architecture)/aws-iam-authenticator.sha256" \
  && if [ "$(openssl sha1 -sha256 /tmp/aws-iam-authenticator | awk '{print $2}')" != "$(cat -s /tmp/aws-iam-authenticator.sha256 | awk '{print $1}')" ]; then openssl sha1 -sha256 /tmp/aws-iam-authenticator; cat /tmp/aws-iam-authenticator.sha256; echo "checksum mismatch"; exit 1; fi \
  && mv /tmp/aws-iam-authenticator ${BINDIR}/aws-iam-authenticator \
  && curl -sSLo "/tmp/eksctl_$(uname -s)_$(dpkg --print-architecture).tar.gz" "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_$(dpkg --print-architecture).tar.gz" \
  && curl -sSLo /tmp/eksctl_checksums.txt "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_checksums.txt" \
  && shasum --ignore-missing -c /tmp/eksctl_checksums.txt \
  && tar xf "/tmp/eksctl_$(uname -s)_$(dpkg --print-architecture).tar.gz" -C /tmp \
  && mv /tmp/eksctl $BINDIR/ \
  && chmod 755 \
      $BINDIR/eksctl \
      $BINDIR/aws-iam-authenticator \
      $BINDIR/kubectl \
      $BINDIR/helmfile \
      $BINDIR/velero \
      $BINDIR/terraform \
      $BINDIR/terragrunt \
# Install helm plugins
  && helm plugin install https://github.com/jkroepke/helm-secrets --version "${HELM_PLUGIN_VERSION_SECRETS}" \
  && helm plugin install https://github.com/aslafy-z/helm-git --version "${HELM_PLUGIN_VERSION_GIT}" \
  && helm plugin install https://github.com/databus23/helm-diff --version "${HELM_PLUGIN_VERSION_DIFF}" \
  && helm plugin install https://github.com/adamreese/helm-env --version "${HELM_PLUGIN_VERSION_ENV}" \
# Install awscli v2
  && if [ "$(dpkg --print-architecture)" != "arm64" ]; then export AWSARCH=x86_64; else export AWSARCH=aarch64; fi \
  && curl -sSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-$AWSARCH.zip \
  && curl -sSLo awscliv2.zip.sig https://awscli.amazonaws.com/awscli-exe-linux-$AWSARCH.zip.sig \
  && gpg --verify awscliv2.zip.sig awscliv2.zip \
  && unzip -q awscliv2.zip \
  && aws/install --install-dir /usr/local/aws-cli --bin-dir $BINDIR \
# Clean up some garbage
  && rm -rf \
    /root/.cache \
    /tmp/* \
    /var/cache/apt/* \
    awscliv2.zip aws \
    /usr/local/aws-cli/v2/*/dist/aws_completer \
    /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
    /usr/local/aws-cli/v2/*/dist/awscli/examples \
  && ${BINDIR}/aws --version \
  && ${BINDIR}/aws-iam-authenticator version \
  && ${BINDIR}/helm version \
  && ${BINDIR}/helmfile --version \
  && ${BINDIR}/kubectl version --client \
  && ${BINDIR}/terraform version \
  && ${BINDIR}/terragrunt --version \
  && ${BINDIR}/velero version --client-only
