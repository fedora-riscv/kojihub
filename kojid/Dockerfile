FROM docker.io/imbearchild/fedora-rv64:39
# FROM fedora:38

HEALTHCHECK --interval=5s --timeout=3s \
  CMD curl -f http://openkoji.iscas.ac.cn/koji || exit 1

# RUN sed -e 's|^metalink=|#metalink=|g' \
#          -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://mirrors.ustc.edu.cn/fedora|g' \
#          -i.bak \
#          /etc/yum.repos.d/fedora.repo \
#          /etc/yum.repos.d/fedora-modular.repo \
#          /etc/yum.repos.d/fedora-updates.repo \
#          /etc/yum.repos.d/fedora-updates-modular.repo

# RUN dnf5 update -y && dnf5 install koji-builder -y
RUN dnf update -y && dnf install koji-builder -y

CMD ["/usr/sbin/kojid", "--fg", "--force-lock", "--verbose"]