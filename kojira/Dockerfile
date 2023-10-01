FROM fedora:38

HEALTHCHECK --interval=5s --timeout=3s \
  CMD curl -f http://kojiweb/koji || exit 1

RUN sed -e 's|^metalink=|#metalink=|g' \
         -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://mirrors.ustc.edu.cn/fedora|g' \
         -i.bak \
         /etc/yum.repos.d/fedora.repo \
         /etc/yum.repos.d/fedora-modular.repo \
         /etc/yum.repos.d/fedora-updates.repo \
         /etc/yum.repos.d/fedora-updates-modular.repo

RUN dnf install curl koji-utils -y

CMD ["/usr/sbin/kojira", "--fg", "--force-lock", "--verbose"]