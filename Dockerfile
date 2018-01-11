FROM binhnv/openjdk
MAINTAINER "Binh Van Nguyen<binhnv80@gmail.com>"

ENV HD_VERSION="2.7.3" \
    
    HBASE_VERSION="1.1.2" \
    HBASE_HOME="${MY_APP_DIR}/hbase" \
    HBASE_HEAPSIZE="256M" \
    HBASE_OFFHEAPSIZE="256M" \
    # https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.2/bk_HDP_Reference_Guide/content/hbase-ports.html
    HBASE_MASTER_PORT="16000" \
    HBASE_MASTER_INFO_PORT="16010" \
    HBASE_REGIONSERVER_PORT="16020" \
    HBASE_REGIONSERVER_INFO_PORT="16030" \
    HBASE_THRIFT_PORT="9090" \
    HBASE_THRIFT_INFO_PORT="9095" \
    HBASE_REST_PORT="8080" \
    HBASE_REST_INFO_PORT="8085" \
    HBASE_CLIENT_RETRIES_NUMBER="3" \
    HBASE_ZOOKEEPER_SESSION_TIMEOUT="30000" \
    HBASE_ZOOKEEPER_RECOVERY_RETRY="0" \

    HD_NAMENODE_HOSTNAME="localhost" \
    HD_DATA_DIR="${MY_APP_DATA_DIR}/hadoop" \
    # overwrite Hadoop configuration environment variable
    HADOOP_PREFIX="${MY_APP_DIR}/hadoop" \
    HADOOP_HDFS_USER="hdfs" \
    HADOOP_YARN_USER="yarn" \
    HADOOP_USER_GROUP="hadoop" \
    HADOOP_MAPRED_USER="mapred" \
    HADOOP_LOG_DIR="${MY_APP_LOG_DIR}/hadoop" \
    YARN_LOG_DIR="${MY_APP_LOG_DIR}/yarn"

ENV HD_DISTRO_NAME="hadoop-${HD_VERSION}" \
    HD_PID_DIR="${DATA_DIR}/pids" \
    HADOOP_CONF_DIR="${HADOOP_PREFIX}/etc/hadoop" \
    HBASE_CONF_DIR="${HBASE_HOME}/conf"

ENV HADOOP_COMMON_HOME="${HADOOP_PREFIX}" \
    HADOOP_MAPRED_HOME="${HADOOP_PREFIX}" \
    YARN_CONF_DIR="${HADOOP_CONF_DIR}" \
    HADOOP_PID_DIR="${HD_PID_DIR}" \
    YARN_PID_DIR="${HD_PID_DIR}" \
    # Hadoop daemons heap size
    HADOOP_HEAPSIZE="256" \
    # YARN daemon heap size
    YARN_HEAPSIZE="256" \
    HADOOP_IDENT_STRING="${HADOOP_HDFS_USER}" \
    YARN_IDENT_STRING="${HADOOP_YARN_USER}" \
    # parameters for configuration files
    HD_MAPREDUCE_FRAMEWORK_NAME="yarn" \
    HD_MAPREDUCE_MAP_MEMORY_MB="512" \
    # amount of memory give to Java map process (75%)
    HD_MAPREDUCE_MAP_JAVA_OPTS="-Xmx384m" \
    HD_MAPREDUCE_REDUCE_MEMORY_MB="512" \
    # amount of memory give to Java reduce process (75%)
    HD_MAPREDUCE_REDUCE_JAVA_OPTS="-Xmx384m" \
    # amount of memory to buffer while sorting before spill to disk
    HD_MAPREDUCE_TASK_IO_SORT_MB="2" \
    HD_YARN_APP_MAPREDUCE_AM_RESOURCE_MB="512" \
    HD_YARN_APP_MAPREDUCE_AM_COMMAND_OPTS="-Xmx400m" \
    HD_YARN_RESOURCEMANAGER_HOSTNAME="localhost" \
    HD_YARN_RESOURCEMANAGER_BIND_HOST="0.0.0.0" \
    HD_YARN_NODEMANAGER_DELETE_DEBUG_DELAY_SEC="600" \
    HD_YARN_SCHEDULER_MINIMUM_ALLOCATION_MB="32" \
    HD_YARN_SCHEDULER_MAXIMUM_ALLOCATION_MB="1536" \
    HD_YARN_NODEMANAGER_RESOURCE_MEMORY_MB="4096" \
    HD_YARN_NODEMANAGER_RESOURCE_CPU_VCORES="4" \
    HD_YARN_NODEMANAGER_VMEM_CHECK_ENABLED="false" \
    HD_DFS_NAMENODE_RPC_BIND_HOST="0.0.0.0" \
    HD_DFS_BLOCKSIZE="1m" \
    HD_DFS_NAMENODE_FS_LIMITS_MIN_BLOCK_SIZE="524288" \
    HD_NAMENODE_NAME_DIR="${HD_DATA_DIR}/nn" \
    HD_CHECKPOINT_DIR="${HD_DATA_DIR}/snn" \
    HD_CHECKPOINT_EDITS_DIR="${HD_DATA_DIR}/snn" \
    HD_DATANODE_DATA_DIR="${HD_DATA_DIR}/dn"

COPY scripts/build /my_build
RUN /my_build/install.sh && rm -rf /my_build

COPY templates ${MY_TEMPLATE_DIR}
COPY scripts/exec /usr/bin/

WORKDIR ${HADOOP_PREFIX}
