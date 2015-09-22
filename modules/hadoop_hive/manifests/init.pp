# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class hadoop_hive(
  $port = 10000,
  $hbase_master = "",
  $hbase_zookeeper_quorum = "",
  $hive_zookeeper_quorum = "",
  $kerberos_realm = "",
  $enable_doas = "false",
  $engine="mr",
  $enable_sql_std_authorization = undef,
  # only configured when kerberos is in use
  $hive_opts = "-Djava.security.auth.login.config=/etc/hive/conf/hive-jaas.conf",
  $hive_cluster_delegation_token_store_zookeeper_acl = "sasl:hive:cdrwa",
) {
  class client (
    $port = $hadoop_hive::port,
    $hbase_master = $hadoop_hive::hbase_master,
    $hbase_zookeeper_quorum = $hadoop_hive::hbase_zookeeper_quorum,
    $hive_zookeeper_quorum = $hadoop_hive::hive_zookeeper_quorum,
    $kerberos_realm = $hadoop_hive::kerberos_realm,
    $enable_doas = $hadoop_hive::enable_doas,
    $engine = $hadoop_hive::engine,
    $enable_sql_std_authorization = $hadoop_hive::enable_sql_std_authorization,
    $hive_opts = $hadoop_hive::hive_opts,
  ) inherits hadoop_hive {
    package { "hive":
      ensure => latest,
      require => Package["jdk"],
    }

    file { "/etc/hive/conf/hive-site.xml":
      content => template('hadoop_hive/hive-site.xml'),
      require => Package["hive"],
    }

    file { "/etc/hive/conf/hive-env.sh":
      content => template('hadoop_hive/hive-env.sh'),
      require => Package["hive"],
    }

    if $kerberos_realm {
      file { "/etc/hive/conf/hive-jaas.conf":
        content => template('hadoop_hive/hive-jaas.conf'),
        require => Package["hive"],
      }
    }
  }

  class server (
    $kerberos_realm = $hadoop_hive::kerberos_realm
  ) inherits hadoop_hive {
    include client

    package { "hive-server2":
      ensure => latest,
      require => Package["jdk"],
    }

    service { "hive-server2":
      ensure => running,
      require =>  Package["hive"],
      subscribe => [File["/etc/hive/conf/hive-site.xml"],File["/etc/hive/conf/hive-env.sh"]],
      hasrestart => true,
      hasstatus => true,
    }

    if ($kerberos_realm) {
      require kerberos::client

      kerberos::host_keytab { "hive":
        spnego => true,
        require => Package["hive-server2"],
      }
    }
  }
}
