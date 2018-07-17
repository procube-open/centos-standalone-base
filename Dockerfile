FROM centos:7
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
RUN yum -y update \
    && yum -y install unzip wget lsof telnet bind-utils tar tcpdump vim strace less python
ENV HOME /root
WORKDIR ${HOME}
RUN echo "export TERM=xterm" >> .bash_profile
ENV container docker
STOPSIGNAL SIGRTMIN+3
RUN systemctl disable getty.target
CMD [ "/sbin/init" ]
