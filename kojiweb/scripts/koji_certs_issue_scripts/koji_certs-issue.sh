#!/bin/bash
#openkoji config
__DEFCONFIGS=./koji_certs-issue_openkoji.conf

#test config
#__DEFCONFIGS=./koji_certs-issue.conf

source $__DEFCONFIGS

if [ -f "${PASSPHRASE_FILE}" ]
then
	OPENSSL_PASS_PHRASE_PASSOUT_OPTIONS="-passout file:${PASSPHRASE_FILE}"
	OPENSSL_PASS_PHRASE_PASSIN_OPTIONS="-passin file:${PASSPHRASE_FILE}"
else
	OPENSSL_PASS_PHRASE_PASSOUT_OPTIONS=''
	OPENSSL_PASS_PHRASE_PASSIN_OPTIONS=''
fi

koji_certs_dir_init ()
{
	#dir init
	sudo mkdir -p ${WORK_DIR}
	echo 'make koji dir for certs issuing work:' ${WORK_DIR}.

	pushd ${WORK_DIR}

	sudo mkdir -p {certs,newcerts,private}
#	sudo mkdir -p newcerts
	sudo rm -f index.txt serial
	sudo touch index.txt serial
	sudo echo '01' | sudo tee serial
	echo 'make dirs/files in koji dir:'
	tree .

	popd
}

koji_ca_certs_issue ()
{
#	pushd ${WORK_DIR}

	sudo openssl genrsa -out ${CA_CERT_PRI_KEY} 2048 \
	&& \
	sudo openssl req -verbose -new -x509 ${OPENSSL_PASS_PHRASE_PASSOUT_OPTIONS} \
		-days ${EXPIRE_DAYS} \
		-config ${SSL_CONF_TEMPLATE} \
		-subj ${SSL_CONF_SUBJ} \
		-out ${CA_CERT_CRT} \
	&& \
	echo 'Generated CA private key and cert file:' ${CA_CERT_CRT}, ${CA_CERT_PRI_KEY}.

#	popd
}

koji_certs_issue ()
{
#	pushd ${WORK_DIR}
	if [ ! -s "${CA_CERT_PRI_KEY}" ] || [ ! -f "${CA_CERT_CRT}" ]
	then
		echo 'ERROR: please issue ca certs file first.'
		return 1
	fi

	if [ "${2}x" != "x" ]
	then
		__ORG_UNIT=${2}
		__EMAIL_ADDR=${2}@${SERVER_NAME}
		__HOST_NAME=${2}
	else
		__ORG_UNIT=${ORG_UNIT}
		__EMAIL_ADDR=${1}@${SERVER_NAME}
		__HOST_NAME=${1}
	fi

	__PRI_KEY=${WORK_DIR}/private/${__HOST_NAME}.key
	__CSR_FILE=${WORK_DIR}/certs/${__HOST_NAME}.csr
	__CRT_FILE=${WORK_DIR}/certs/${__HOST_NAME}.crt
	__PEM_FILE=${WORK_DIR}/${__HOST_NAME}.pem

	__COMMON_NAME=${1}
	__SSL_CONF_SUBJ="${SSL_CONF_SUBJ_COM}/OU=${__ORG_UNIT}/CN=${__COMMON_NAME}/emailAddress=${__EMAIL_ADDR}"

	sudo openssl genrsa \
		-out ${__PRI_KEY} 2048 \
	&& \
	sudo openssl req -new -nodes ${OPENSSL_PASS_PHRASE_PASSOUT_OPTIONS} \
		-config ${SSL_CONF_TEMPLATE} \
		-subj ${__SSL_CONF_SUBJ} \
		-key ${__PRI_KEY} \
		-out ${__CSR_FILE} \
	&& \
	sudo openssl ca -batch ${OPENSSL_PASS_PHRASE_PASSIN_OPTIONS} \
		-config ${SSL_CONF_TEMPLATE} \
		-out ${__CRT_FILE} \
		-infiles ${__CSR_FILE} \
	&& \
	sudo cat ${__CRT_FILE} ${__PRI_KEY}  | sudo tee ${__PEM_FILE} > /dev/null \
	&& \
	echo Generated the new pem file for ${__HOST_NAME}: ${__PEM_FILE}

#	popd
}

koji_components_certs_issue ()
{
	koji_certs_issue ${COMMON_NAME} kojihub
	koji_certs_issue ${COMMON_NAME} kojiweb
	koji_certs_issue kojira
	koji_certs_issue kojiadmin
}

koji_cn_list_gen ()
{
	if [ -f "${CN_LIST_FILE}" ]
	then
		mv ${CN_LIST_FILE} ${CN_LIST_FILE}_`date +%Y%m%d%H%M%S`.bak
	fi

	CN_NUM_LIST=`seq -f "%0${CN_NUM_WIDTH}g" $CN_NUM_START $CN_NUM_STEP $CN_NUM_END`
	for num in ${CN_NUM_LIST}
	do
		echo ${CN_PREFIX}${num}${CN_SUBFIX} >> ${CN_LIST_FILE}
	done
}

koji_cn_list_certs_issue ()
{
	while read line
	do
            koji_certs_issue $line || break
	done < ${CN_LIST_FILE}
}

koji_cn_list_certs_packup ()
{
	mkdir -p ${CERTS_DIR}

	while read line
	do
            cp  ${WORK_DIR}/$line.pem ${CERTS_DIR}/ || break
	done < ${CN_LIST_FILE}

	cp  ${CA_CERT_CRT} ${CERTS_DIR}/
}

_koji_builder_register ()
{
	koji add-host ${1} ${BUILDER_ARCH}
}

koji_builders_register ()
{
	while read line
	do
            _koji_builder_register $line || break
	done < ${CN_LIST_FILE}
}

koji_certs_reset ()
{
	sudo rm -rf ${WORK_DIR}
	rm -f ${CN_LIST_FILE}
	rm -f .rand
}

koji_certs_browser ()
{
	__USER_NAME=${1}
	__PRI_KEY=${WORK_DIR}/private/${__USER_NAME}.key
	__CRT_FILE=${WORK_DIR}/certs/${__USER_NAME}.crt
	__P12_FILE=${WORK_DIR}/certs/${__USER_NAME}_browser_cert.p12
	if [ ! -f "${__CRT_FILE}" ] || [ ! -f "${__PRI_KEY}" ] || [ ! -f "${CA_CERT_CRT}" ]
	then
		echo "ERROR: please issue ca or ${__USER_NAME} certs file first."
		return 1
	fi

	sudo openssl pkcs12 -export \
		-inkey ${__PRI_KEY} \
		-in ${__CRT_FILE} \
		-CAfile ${CA_CERT_CRT} \
		-out ${__P12_FILE} \
	&& \
	echo Generated the new p12 file for ${__USER_NAME}: ${__P12_FILE}
}

koji_certs_install ()
{
	__USER_NAME=${1}
	# 注意：用户证书需要用 PEM 文件而不是 CRT
	__PEM_FILE=${WORK_DIR}/${__USER_NAME}.pem

	if [ ! -f "${__PEM_FILE}" ] || [ ! -f "${CA_CERT_CRT}" ]
	then
		echo "ERROR: please issue ca or ${__PEM_FILE} certs file first."
		return 1
	fi

	mkdir -p ~/.koji \
	&& \
	cp ${__PEM_FILE} ~/.koji/client.crt \
	&& \
	cp ${CA_CERT_CRT} ~/.koji/serverca.crt \
	&& \
	echo Install the files for ${__USER_NAME}:
	tree ~/.koji	
}

help_msg ()
{
	echo '-d, dirs init'
	echo '-c, ca certs gen'
	echo '-m, modules(components) certs gen'
	echo '-l, generate name list only'
	echo '-f, for name list, generating certs base on'  
	echo '-s <common name>, single cert gen for a CN'
	echo '-b <common name of user>, generating browser p12 cert'
	echo '-i <common name of user>, install koji user serts'  
	echo '-r, reset certs files'
	echo '-a, all-in-one'
}

#d, dirs init
#c, ca certs gen
#m, modules(components) certs gen
#l, generate name list only
#f, for name list, generating certs base on  
#s, single cert gen
#a, all-in-one

while getopts "C:dcmlfps:b:i:arRh" arg
#选项后面的冒号表示该选项需要参数
do
    case $arg in
        C)
            source $OPTARG
            ;;
        S)
            CN_NUM_START=$OPTARG
            ;;
        P)
            CN_NUM_STEP=$OPTARG
            ;;
        E)
            CN_NUM_END=$OPTARG
            ;;
        W)
            CN_NUM_WIDTH=$OPTARG
            ;;
        d)
            koji_certs_dir_init
            exit 0
            ;;
        c)
            koji_ca_certs_issue
            exit 0
            ;;
        m)
            koji_components_certs_issue
            exit 0
            ;;
        l)
            koji_cn_list_gen
            exit 0
            ;;
        f)
            koji_cn_list_certs_issue
            exit 0
            ;;
        p)
            koji_cn_list_certs_packup
            exit 0
            ;;
        s)
            koji_certs_issue $OPTARG
            exit 0
            ;;
        b)
            koji_certs_browser $OPTARG
            exit 0
            ;;
        i)
            koji_certs_install $OPTARG
            exit 0
            ;;
        a)
            koji_certs_dir_init
            koji_ca_certs_issue
            koji_components_certs_issue
            koji_cn_list_gen
            koji_cn_list_certs_issue
            exit 0
            ;;
        r)
            koji_certs_reset
            exit 0
            ;;
        R)
            koji_builders_register
            exit 0
            ;;
        h)  
            help_msg
            exit 0
            ;;
        *)  
		#当有不认识的选项的时候arg为?
            echo "unknown argument"
            help_msg
            exit 1
	    ;;
    esac
#    echo $arg
done

shift $((OPTIND-1))

