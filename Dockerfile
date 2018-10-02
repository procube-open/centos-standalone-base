FROM centos:7
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
RUN yum -y update \
    && yum -y install unzip wget lsof telnet bind-utils tar tcpdump vim strace less python
ENV HOME /root
WORKDIR ${HOME}
RUN echo "export TERM=xterm" >> .bash_profile
ENV container docker
STOPSIGNAL SIGRTMIN+3
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]
CMD [ "/sbin/init" ]
