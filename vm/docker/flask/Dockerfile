FROM centos:7
MAINTAINER richyen@yahoo.com
ENV LC_ALL=en_US.utf8
RUN yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
RUN yum -y install centos-release-scl epel-release postgresql12-devel
RUN yum -y install rh-python36
RUN yum -y groupinstall "Development Tools"
RUN scl enable rh-python36 bash && \
    mkdir my_flask_app && \
    cd my_flask_app && \
    /opt/rh/rh-python36/root/usr/bin/python3 -m venv venv && \
    source venv/bin/activate && \
    pip install --upgrade pip && \
    pip install Flask

EXPOSE 5000 80
CMD tail -f /dev/null
