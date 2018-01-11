#!/usr/bin/env bash

# exit immediately if there is error
set -e

# some global variables
g_group="${HADOOP_USER_GROUP}"
g_app_dir="${HADOOP_PREFIX}"
g_hdfs_user="${HADOOP_HDFS_USER}"
g_yarn_user="${HADOOP_YARN_USER}"
g_mapred_user="${HADOOP_MAPRED_USER}"
g_users="${g_hdfs_user} ${g_yarn_user} ${g_mapred_user}"
g_pkg_url="http://archive.apache.org/dist/hadoop/common/${HD_DISTRO_NAME}/${HD_DISTRO_NAME}.tar.gz"
g_conf_dir="${HADOOP_CONF_DIR}"
g_nn_dir="${HD_NAMENODE_NAME_DIR}"
g_cp_dir="${HD_CHECKPOINT_DIR}"
g_cpe_dir="${HD_CHECKPOINT_EDITS_DIR}"
g_dnd_dir="${HD_DATANODE_DATA_DIR}"
g_hadoop_log_dir="${HADOOP_LOG_DIR}"
g_yarn_log_dir="${YARN_LOG_DIR}"
g_pid_dir="${HD_PID_DIR}"

g_hbase_home="${HBASE_HOME}"
g_hbase_bin_url="https://github.com/binhnv/hbase-binaries/releases/download/v${HBASE_VERSION}-hadoop-${HD_VERSION}/hbase-${HBASE_VERSION}-bin.tar.gz"

function update_ssh_config {
    local ssh_dir=$1

    mkdir -p "${ssh_dir}"
    cat > ${ssh_dir}/config<<QUIET_CONFIG
Host *
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  LogLevel quiet
QUIET_CONFIG
}

function setup_user_ssh {
    local u=$1 g=$2
    local home_dir=$( getent passwd "${u}" | cut -d: -f6 )
    local ssh_dir="${home_dir}/.ssh"

    update_ssh_config ${ssh_dir}
    ssh-keygen -q -N "" -t rsa -f "${ssh_dir}/id_rsa"
    cat "${ssh_dir}/id_rsa.pub" >> "${ssh_dir}/authorized_keys"

    chown -R ${u}:${g} "${ssh_dir}"
    chmod 640 "${ssh_dir}/authorized_keys"
}

function setup_users {    
    # add group if it is not there yet
    groupadd -f ${g_group}
    # add user if it is not there yet
    for u in ${g_users}; do
        id -u ${u} &> /dev/null || \
            useradd -m -g ${g_group} ${u} && echo ${u}:${u} | chpasswd
        setup_user_ssh ${u} ${g_group}
    done
    setup_user_ssh "root" "root"
}

function install_hbase {
    mkdir -p ${g_hbase_home}

    echo "Downloading ${g_hbase_bin_url}..."
    curl -sL ${g_hbase_bin_url} | tar -xz -C ${g_hbase_home} --strip-component=1
    ln -s ${g_hbase_home}/conf/hbase-site.xml ${g_conf_dir}/hbase-site.xml
}

function setup_package {
    echo "Downloading ${g_pkg_url}..."
    mkdir -p ${g_app_dir}
    curl -Ls ${g_pkg_url} | tar -xz -C ${g_app_dir} --strip-components=1
    ln -s ${g_app_dir}/bin/hadoop /usr/bin/hadoop
    
    echo "Installing dependencies..."
    apt-get update
    apt-get install -y --no-install-recommends \
        openssh-client
    
    echo ". /etc/container_environment.sh" >> "${g_conf_dir}/hadoop-env.sh"
}

function setup_dirs {
    mkdir -p ${g_nn_dir} ${g_cp_dir} ${g_cpe_dir} ${g_dnd_dir}
    chown -R ${g_hdfs_user}:${g_group} ${g_nn_dir} ${g_cp_dir} ${g_cpe_dir} ${g_dnd_dir}
    chmod u+w ${g_nn_dir} ${g_cp_dir} ${g_cpe_dir} ${g_dnd_dir}

    mkdir -p ${g_hadoop_log_dir} ${g_pid_dir} ${g_yarn_log_dir}
    chgrp ${g_group} ${g_hadoop_log_dir} ${g_pid_dir} ${g_yarn_log_dir}
    chmod g+w ${g_hadoop_log_dir} ${g_pid_dir} ${g_yarn_log_dir}
}

function generate_keystore {
    local pass="h@doop"
    local keystore_dir="/etc/security/keystore"
    local keystore_file="${keystore_dir}/hadoop.keystore"
    local cert_file="${keystore_dir}/hadoop.cert"
    local truststore_file="${keystore_dir}/hadoop.truststore"

    mkdir -p ${keystore_dir}
    keytool -genkey -keystore ${keystore_file} -keyalg RSA \
        -dname "CN=hadoop,O=myorg" -keypass ${pass} -storepass ${pass}
    keytool -exportcert -keystore ${keystore_file} \
        -file ${cert_file} -storepass ${pass}
    keytool -import -keystore ${truststore_file} \
        -file ${cert_file} -noprompt -storepass ${pass}
    
    cp ${keystore_file} ${truststore_file} ${g_conf_dir}
    chmod 0444 ${truststore_file}
    chmod 0440 ${keystore_file}
}

function generate_http_auth_secret {
    # http://docs.hortonworks.com/HDPDocuments/Ambari-2.2.1.1/bk_Ambari_Security_Guide/content/_configuring_http_authentication_for_HDFS_YARN_MapReduce2_HBase_Oozie_Falcon_and_Storm.html
    mkdir -p /etc/security/hadoop
    dd if=/dev/urandom of=/etc/security/hadoop/http_secret bs=1024 count=1
    chown ${g_hdfs_user}:${g_group} /etc/security/hadoop/http_secret
    chmod 0440 /etc/security/hadoop/http_secret
}

function cleanup {
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}

function main {
    setup_users
    setup_package
    setup_dirs
    install_hbase
    generate_keystore
    generate_http_auth_secret

    chgrp -R ${g_group} ${g_app_dir}
    # http://pivotalhd-210.docs.pivotal.io/doc/2100/webhelp/topics/ConfiguringKerberosforHDFSandYARNMapReduce.html#modifyingcontainerandscript
    chmod 050 ${g_app_dir}/bin/container-executor
    chmod u+s,g+s ${g_app_dir}/bin/container-executor
    chmod 0400 ${g_conf_dir}/container-executor.cfg
    chgrp -R ${g_group} /etc/security/keystore

    cleanup
}

main "$@"
