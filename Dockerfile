FROM         gocd/gocd-agent:17.1.0
MAINTAINER   Ahmad <ahmad@aurorasolutions.io>

RUN          apt-get -y update \
             && apt-get -y install jq python-pip uuid wget libltdl7
RUN          pip install --upgrade awscli

RUN          apt-get clean

# Install terraform
RUN          mkdir -p /opt/terraform \
             && wget -nc -q https://releases.hashicorp.com/terraform/0.8.6/terraform_0.8.6_linux_amd64.zip -P /opt/terraform \
             && unzip -q /opt/terraform/terraform_0.8.6_linux_amd64.zip -d /opt/terraform
ENV PATH     /opt/terraform:$PATH

ADD          sudoers/go /etc/sudoers.d/
RUN          chmod 755 /etc/sudoers.d/go

# base image's cmd
CMD          ["/sbin/my_init"]
