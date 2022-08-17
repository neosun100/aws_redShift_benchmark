# AWS_redshift_benchmark

RedShift Benchmark Tools of user customized scripts
## 0. Create a cluster and import the data you need to test
Create environment variables related to redshift configuration. Adjust the following values for your environment
```zsh
export REDSHIFT_HOSTNAME=
export REDSHIFT_PORT=5439
export REDSHIFT_DATABASE=dev
export REDSHIFT_USERNAME=root
export RSPASSWORD=
```
## 1. Setup ODBC,Rsql and init Environment

Create environment variables to install command line tools
The client version will be updated at any time, please pay attention to the updated version of link
```zsh
# https://docs.aws.amazon.com/redshift/latest/mgmt/configure-odbc-connection.html#odbc-driver-linux-how-to-install
ODBC_VERSION=1.4.56.1000
# https://docs.aws.amazon.com/redshift/latest/mgmt/rsql-query-tool-getting-started.html
RSQL_VERSION=1.0.5
```

Next, perform the steps according to different systems

### 1.1 Linux CentOS or Amazon

```zsh
sudo yum install unixODBC openssl -y
sudo rpm -i \
    https://s3.amazonaws.com/redshift-downloads/drivers/odbc/${ODBC_VERSION}/AmazonRedshiftODBC-64-bit-${ODBC_VERSION}-1.x86_64.rpm \
    https://s3.amazonaws.com/redshift-downloads/amazon-redshift-rsql/${RSQL_VERSION}/AmazonRedshiftRsql-${RSQL_VERSION}-1.x86_64.rpm

cp -f /opt/amazon/redshiftodbc/Setup/odbc.ini ~/.odbc.ini
export ODBCINI=~/.odbc.ini
export ODBCSYSINI=/opt/amazon/redshiftodbc/Setup
export AMAZONREDSHIFTODBCINI=/opt/amazon/redshiftodbc/lib/64/amazon.redshiftodbc.ini

rsql --version
```

### 1.2 MAC

```zsh
 wget -N -t 0 -c -P /tmp/ https://s3.amazonaws.com/redshift-downloads/drivers/odbc/$ODBC_VERSION/AmazonRedshiftODBC-$ODBC_VERSION.dmg
 wget -N -t 0 -c -P /tmp/ https://s3.amazonaws.com/redshift-downloads/amazon-redshift-rsql/$RSQL_VERSION/AmazonRedshiftRsql-$RSQL_VERSION.dmg
open /tmp/AmazonRedshiftODBC-$ODBC_VERSION.dmg
oepn /tmp/AmazonRedshiftRsql-$RSQL_VERSION.dmg

cp -f /opt/amazon/redshiftodbc/Setup/odbc.ini ~/.odbc.ini
export ODBCINI=~/.odbc.ini
export ODBCSYSINI=/opt/amazon/redshift/Setup
export AMAZONREDSHIFTODBCINI=/opt/amazon/redshift/lib/amazon.redshiftodbc.ini
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/usr/local/lib

rsql --version
```

## 2. init result Table
```zsh
source init/init_rsql.sh
init_rsql
init_rsql_benchmark_table
```

## 3. Benchmark 
Run a user-defined script, default to one script for 3 times
Point SCRIPT_DIR to the script directory that needs to be tested
```zsh
export SCRIPT_DIR=/tmp
```
```zsh
cd $SCRIPT_DIR
for i in $(ls $SCRIPT_DIR); do benchmark_redshift $i ; done
```

## 4. View benchmark results table

`public.redshift_benchmark_statistical_table`
COMMENT as follows
```sql
-- 表注释
COMMENT ON TABLE public.redshift_benchmark_statistical_table IS 'This table stores redshift benchmark data';

-- 字段注释
COMMENT ON COLUMN public.redshift_benchmark_statistical_table.use_type IS '用例的类型';
COMMENT ON COLUMN public.redshift_benchmark_statistical_table.sub_use_type IS '用例子类型';
COMMENT ON COLUMN public.redshift_benchmark_statistical_table.use_case IS '用例名称';
COMMENT ON COLUMN public.redshift_benchmark_statistical_table.running_Sequence IS '执行的序列';
COMMENT ON COLUMN public.redshift_benchmark_statistical_table.query_id IS 'integer	查询 ID。如果重新启动了某个查询，则会为该查询分配一个新的查询 ID 但不分配新的任务 ID';
COMMENT ON COLUMN public.redshift_benchmark_statistical_table.exec_start_time IS 'timestamp	查询开始在服务类中执行的时间。';
COMMENT ON COLUMN public.redshift_benchmark_statistical_table.exec_end_time IS 'timestamp	查询在服务类中完成执行的时间。';
COMMENT ON COLUMN public.redshift_benchmark_statistical_table.total_exec_time IS '查询在服务类中完成执行的时间。';
COMMENT ON COLUMN public.redshift_benchmark_statistical_table.slot_count IS 'integer	WLM 查询槽位数。';
COMMENT ON COLUMN public.redshift_benchmark_statistical_table.final_state IS '执行后的状态';
COMMENT ON COLUMN public.redshift_benchmark_statistical_table.query_priority IS '执行优先级';
COMMENT ON COLUMN public.redshift_benchmark_statistical_table.sqlquery IS '具体执行的SQL';
COMMENT ON COLUMN public.redshift_benchmark_statistical_table.concurrency_scaling_status IS '并发扩展 指示查询运行在主集群还是并发扩展集群上。可能值如下所示：0 - 运行在主集群上；1 - 运行在并发扩展集群上；> 1 - 运行在主集群上 ';

```

## Appendix
There is a docker image in the init directory for emergencies.