init_rsql() {
    if [ $(uname -m) = "armv7l" ] && [ $(uname) = "Linux" ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') 本系统为arm Linux" | lcat
        export ODBCINI=~/.odbc.ini
        export ODBCSYSINI=/opt/amazon/redshiftodbc/Setup
        export AMAZONREDSHIFTODBCINI=/opt/amazon/redshiftodbc/lib/64/amazon.redshiftodbc.ini
        #   typeset sysname="_linux_arm"
        # 执行代码块
    elif [ $(uname -m) = "x86_64" ] && [ $(uname) = "Linux" ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') 本系统为X86 Linux" | lcat
        cp -f /opt/amazon/redshiftodbc/Setup/odbc.ini ~/.odbc.ini
        export ODBCINI=~/.odbc.ini
        export ODBCSYSINI=/opt/amazon/redshiftodbc/Setup
        export AMAZONREDSHIFTODBCINI=/opt/amazon/redshiftodbc/lib/64/amazon.redshiftodbc.ini
        #   typeset sysname="_linux_amd64"
        # 执行代码块
    elif [ $(uname -m) = "x86_64" ] && [ $(uname) = "Darwin" ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') 本系统为X86 Mac"
        export ODBCINI=~/.odbc.ini
        export ODBCSYSINI=/opt/amazon/redshift/Setup
        export AMAZONREDSHIFTODBCINI=/opt/amazon/redshift/lib/amazon.redshiftodbc.ini
        export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/usr/local/lib
    else
        echo "$(uname) 系统未知！"
    fi

}

init_rsql_benchmark_table() {
    rsql \
        -U $REDSHIFT_USERNAME \
        -h $REDSHIFT_HOSTNAME \
        -d $REDSHIFT_DATABASE \
        -p $REDSHIFT_PORT \
        -t \
        -c "create table if not exists public.redshift_benchmark_statistical_table
(
    use_type                   varchar(255)   NOT NULL DEFAULT '0',
    sub_use_type               varchar(255)   NOT NULL DEFAULT '0',
    use_case                   varchar(255)   NOT NULL DEFAULT '0',
    running_Sequence           int            NOT NULL DEFAULT 0,
    query_id                   int            NOT NULL DEFAULT 0,
    exec_start_time            timestamp,
    exec_end_time              timestamp,
    total_exec_time            int8           NOT NULL DEFAULT 0,
    slot_count                 int            NOT NULL DEFAULT 0,
    final_state                varchar(255)   NOT NULL DEFAULT '0',
    query_priority             varchar(255)   NOT NULL DEFAULT '0',
    sqlquery                   varchar(10240) NOT NULL DEFAULT '0',
    concurrency_scaling_status int            NOT NULL DEFAULT 0

);"
}

# 参考链接 https://github.com/ClickHouse/ClickBench/tree/main/redshift
benchmark_redshift() {

    # 使用方式
    # 参数1 必选，需要跑的SQL文件
    # 参数2 可选，sql type
    # 参数3 可选，sql sub-type
    # 参数4 可选，sql use case
    # 🚀 写法注意需要双引号内加单引号，redshift 相关
    # benchmark_redshift
    # benchmark_redshift /tmp/redshift_demo.sql
    # benchmark_redshift /tmp/redshift_demo.sql "'this is type'"   "'this is sub_type'"  "'this is use_case'"

    TRIES=3
    # 💥 这个参数是需要单sql跑的次数 ，默认1次
    SQL_FILE=${1:-/tmp/redshift_demo.sql}
    SQL_NAME="$(basename $SQL_FILE)"
    USE_TYPE=${2:-\' \'}
    SUB_USE_TYPE=${3:-\' \'}
    USE_CASE=${4:-\' \'}
    # echo $SQL_FILE
    # echo $SQL_NAME
    # echo $USE_TYPE
    # echo $SUB_USE_TYPE
    # echo $USE_CASE

    for num in $(seq 1 $TRIES); do
        rsql \
            -U $REDSHIFT_USERNAME \
            -h $REDSHIFT_HOSTNAME \
            -d $REDSHIFT_DATABASE \
            -p $REDSHIFT_PORT \
            -t \
            -c 'SET enable_result_cache_for_session = off' \
            -c "`cat $SQL_FILE`" \
            -c "INSERT INTO public.redshift_benchmark_statistical_table
(select
    $USE_TYPE as use_type,
    $SUB_USE_TYPE as sub_use_type,
    $USE_CASE as use_case,
    $num as running_Sequence,
    stl_wlm_query.query as query_id,
    stl_wlm_query.exec_start_time,
    stl_wlm_query.exec_end_time,
    stl_wlm_query.total_exec_time,
    stl_wlm_query.slot_count,
    stl_wlm_query.final_state,
    stl_wlm_query.query_priority,
    trim(stl_query.querytxt) as sqlquery,
    stl_query.concurrency_scaling_status
from stl_wlm_query,stl_query
where stl_wlm_query.query = stl_query.query and stl_query.query = pg_last_query_id());
" >/dev/null 2>&1

    done
}
