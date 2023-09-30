#!/bin/bash

# 判断是否有koji密钥来决定是否初始化
if [ ! -d "/etc/pki/koji/private"  ]; then 
    pushd /opt/koji_certs_issue_scripts
    sh /usr/local/bin/setup_koji.sh
    popd
fi

httpd -D FOREGROUND