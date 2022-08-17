# https://docs.aws.amazon.com/zh_cn/AL2/latest/relnotes/relnotes-al2.html
FROM amazonlinux:2.0.20220719.0
# https://docs.aws.amazon.com/redshift/latest/mgmt/configure-odbc-connection.html#odbc-driver-linux-how-to-install
ENV ODBC_VERSION=1.4.56.1000
# https://docs.aws.amazon.com/redshift/latest/mgmt/rsql-query-tool-getting-started.html
ENV RSQL_VERSION=1.0.5

RUN yum update -y && \
    yum install -y unixODBC less && \
    yum clean all

RUN rpm -i \
    https://s3.amazonaws.com/redshift-downloads/drivers/odbc/${ODBC_VERSION}/AmazonRedshiftODBC-64-bit-${ODBC_VERSION}-1.x86_64.rpm \
    https://s3.amazonaws.com/redshift-downloads/amazon-redshift-rsql/${RSQL_VERSION}/AmazonRedshiftRsql-${RSQL_VERSION}-1.x86_64.rpm

RUN cp /opt/amazon/redshiftodbc/Setup/odbc.ini ~/.odbc.ini
RUN ln -s /usr/bin/less /usr/bin/more

ENV ODBCINI=~/.odbc.ini
ENV ODBCSYSINI=/opt/amazon/redshiftodbc/Setup
ENV AMAZONREDSHIFTODBCINI=/opt/amazon/redshiftodbc/lib/64/amazon.redshiftodbc.ini

ENTRYPOINT ["/usr/bin/rsql"]