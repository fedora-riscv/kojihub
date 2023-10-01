FROM fedora:38

HEALTHCHECK --interval=5s --timeout=3s \
  CMD curl -f http://localhost/koji || exit 1

RUN sed -e 's|^metalink=|#metalink=|g' \
         -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://mirrors.ustc.edu.cn/fedora|g' \
         -i.bak \
         /etc/yum.repos.d/fedora.repo \
         /etc/yum.repos.d/fedora-modular.repo \
         /etc/yum.repos.d/fedora-updates.repo \
         /etc/yum.repos.d/fedora-updates-modular.repo

RUN dnf install curl mod_ssl httpd git koji-hub koji-web koji-utils openssl tree -y

# 安装完后再挪过来
# RUN mkdir -p /etc/default/koji /etc/default/httpd

# RUN cp /etc/koji.conf /etc/default/koji/koji.conf && \
#     cp -r /etc/koji.conf.d /etc/default/koji/koji.conf.d && \
#     cp -r /etc/koji-gc /etc/default/koji/koji-gc && \
#     cp -r /etc/koji-hub /etc/default/koji/koji-hub && \
#     cp -r /etc/kojiweb /etc/default/koji/kojiweb && \
#     cp -r /etc/kojira /etc/default/koji/kojira && \
#     cp -r /etc/koji-shadow /etc/default/koji/koji-shadow && \
#     cp -r /etc/httpd /etc/default/httpd

COPY bin/entrypoint.sh /usr/local/bin/
COPY bin/setup_koji.sh /usr/local/bin/

COPY scripts/koji_certs_issue_scripts /opt/koji_certs_issue_scripts

RUN chmod +x /usr/local/bin/entrypoint.sh && chmod +x /opt/koji_certs_issue_scripts/koji_certs-issue.sh

ENTRYPOINT /usr/local/bin/entrypoint.sh
