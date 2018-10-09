# centos-standalone-base

スタンドアローン型のコンテナのベースとなるイメージである。以下に Dockerfile 内の設定について説明する。

## 3行目
```
yum update
```
OSを更新する。マイナー番号も最新となるので、注意が必要である。

## ４行目
```
yum -y install unzip wget lsof telnet bind-utils tar tcpdump vim strace less python
```
ビルドやデバッグに必要となる標準的なツールをインストールする。

## 5-7行目
```
ENV HOME /root
WORKDIR ${HOME}
RUN echo "export TERM=xterm" >> .bash_profile
```
docker exec でシェルを実行する際に、ログインしたのと近い状態にする。

## 8行目
```
ENV container docker
```
シャットダウン後に systemd のプロセスを終了するように環境変数を設定する。
https://github.com/systemd/systemd/blob/master/src/basic/virt.c
の detect_container でこの環境変数を検知するが、systemd のソースコードで detect_container を検索すると36個ヒットする。様々な処理の判断で使われているが、そのうちの１個でシャットダウン時の挙動の決定にも使われている。

## 9行目
```
STOPSIGNAL SIGRTMIN+3
```
docker stop でシャットダウンプロセスを実行するようにする。

## 10-18行目
```
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
```
[centos のコード](https://hub.docker.com/_/centos/)を参考にすべてのサービスをdisable する。
この設定がないと、[複数のコンテナを同時起動したときに agetty が CPU を専有する症状が出る場合がある](https://blog.nekonekonekko.net/?p=374)。ただし、上記で disable したものでも、 preset が enable の場合、ユニットに対して
```
systemctl is-enabled ユニット名
```
を実行すると true が返るので注意を要する。特に ansible の service モジュールで enable すると、上記のコマンドで冪等性を確保するようにコーディングされていて、 enable にならない。たとえば、
```
service: name=rsyslog enabled=yes
```
としても rsyslog は enable にならないので注意。
参考：https://github.com/ansible/ansible-modules-core/issues/3764
```
- name: enable rsyslog service
  shell: systemctl enable rsyslog
```
と書く必要がある。  

## 19行目
docker run のときに -v でホストの同じパスをマウントするボリュームを明示している。docker swarm mode では、 --privledged は使えないため、内部で systemctl を利用するためにはこの /sys/fs/cgroup　と　/run をマウントすることが必須となる。docker-compose.yml のサンプルを示す。
```
version: "3.4"
services:
  test:
    image: "procube/centos-standalone-base:latest"
    hostname: "test"
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
      - run_vol:/run
volumes:
  run_vol:
    driver_opts:
      type: tmpfs
      device: tmpfs
```
