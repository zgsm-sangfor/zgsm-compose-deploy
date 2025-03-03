#
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
#
apisix:
  node_listen: {{PORT_APISIX_ENTRY}}              # APISIX listening port
  enable_ipv6: false
  enable_control: true
  control:
    ip: "0.0.0.0"
    port: 9092
deployment:
  admin:
    allow_admin:               # https://nginx.org/en/docs/http/ngx_http_access_module.html#allow
      - 0.0.0.0/0              # We need to restrict ip access rules for security. 0.0.0.0/0 is for test.
    admin_key:
      - name: "admin"
        key: {{APIKEY_APISIX_ADMIN}}
        role: admin                 # admin: manage all configuration data
      - name: "viewer"
        key: {{APIKEY_APISIX_VIEWER}}
        role: viewer
  etcd:
    host:                           # it's possible to define multiple etcd hosts addresses of the same etcd cluster.
      - "http://{{ZGSM_BACKEND}}:{{PORT_ETCD}}"          # multiple etcd address
    prefix: "/apisix"               # apisix configurations prefix
    timeout: 30                     # 30 seconds
plugin_attr:
  prometheus:
    export_addr:
      ip: "0.0.0.0"
      port: {{PORT_APISIX_PROMETHEUS}}
nginx_config:
  http_end_configuration_snippet: |
    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;
