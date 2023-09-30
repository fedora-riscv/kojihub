#!/bin/bash

/opt/koji_certs_issue_scripts/koji_certs-issue.sh -C /opt/koji_certs_issue_scripts/koji_certs-issue_openkoji.conf -d
/opt/koji_certs_issue_scripts/koji_certs-issue.sh -C /opt/koji_certs_issue_scripts/koji_certs-issue_openkoji.conf -c
/opt/koji_certs_issue_scripts/koji_certs-issue.sh -C /opt/koji_certs_issue_scripts/koji_certs-issue_openkoji.conf -m

