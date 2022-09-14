FROM docker:20.10.12 as static-docker-source


FROM python:latest
ARG CLOUD_SDK_VERSION=402.0.0
ENV CLOUD_SDK_VERSION=$CLOUD_SDK_VERSION
ENV PATH /google-cloud-sdk/bin:$PATH
COPY --from=static-docker-source /usr/local/bin/docker /usr/local/bin/docker
RUN groupadd -r -g 1000 cloudsdk && \
    useradd -r -u 1000 -m -s /bin/bash -g cloudsdk cloudsdk
RUN apt-get -qqy update && apt-get install -qqy \
        curl \
        gcc \
        apt-transport-https \
        lsb-release \
        openssh-client \
        git \
        make \
        gnupg
RUN if [ `uname -m` = 'x86_64' ]; then echo -n "x86_64" > /tmp/arch; else echo -n "arm" > /tmp/arch; fi;
RUN ARCH=`cat /tmp/arch` && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz && \
    tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz && \
    rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz
RUN echo -n "app-engine-java app-engine-python alpha beta pubsub-emulator cloud-datastore-emulator app-engine-go bigtable cbt datalab app-engine-python-extras kubectl gke-gcloud-auth-plugin kustomize minikube skaffold kpt local-extract" > /tmp/additional_components
# These components are not available on ARM right now.
RUN if [ `uname -m` = 'x86_64' ]; then echo -n " appctl nomos anthos-auth" >> /tmp/additional_components; fi;
RUN /google-cloud-sdk/install.sh --bash-completion=false --path-update=true --usage-reporting=false \
	--additional-components `cat /tmp/additional_components` && rm -rf /google-cloud-sdk/.install/.backup
RUN git config --system credential.'https://source.developers.google.com'.helper gcloud.sh
VOLUME ["/root/.config", "/root/.kube"]