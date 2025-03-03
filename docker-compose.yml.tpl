version: '3.8'

services:
  apisix:
    image: apache/apisix:3.9.1-debian
    restart: always
    environment:
      TZ: "Asia/Shanghai"
    volumes:
      - ./apisix/config.yaml:/usr/local/apisix/conf/config.yaml:ro
    depends_on:
      - etcd
    ports:
      - "{{PORT_APISIX_API}}:9180/tcp"
      - "{{PORT_APISIX_ENTRY}}:9080/tcp"
      - "{{PORT_APISIX_PROMETHEUS}}:9091/tcp"
    networks:
      - shenma

  apisix-dashboard:
    image: apache/apisix-dashboard:3.0.0-alpine
    restart: always
    environment:
      TZ: "Asia/Shanghai"
    volumes:
      - ./apisix_dashboard/conf.yaml:/usr/local/apisix-dashboard/conf/conf.yaml
    depends_on:
      - etcd
    ports:
      - "{{PORT_APISIX_DASHBOARD}}:9000/tcp"
    networks:
      - shenma

  etcd:
    image: bitnami/etcd:3.5.14
    restart: always
    volumes:
      - ./etcd/data:/bitnami/etcd/data
    user: "1000:1000"
    environment:
      TZ: "Asia/Shanghai"
      ETCD_ENABLE_V2: "true"
      ALLOW_NONE_AUTHENTICATION: "yes"
      ETCD_ADVERTISE_CLIENT_URLS: "http://{{ZGSM_BACKEND}}:{{PORT_ETCD}}"
      ETCD_LISTEN_CLIENT_URLS: "http://0.0.0.0:{{PORT_ETCD}}"
    ports:
      - "{{PORT_ETCD}}:{{PORT_ETCD}}/tcp"
    networks:
      - shenma

  redis:
    image: docker.io/redis:7.2.4
    restart: always
    environment:
      TZ: "Asia/Shanghai"
    volumes:
      - ./redis/data:/data
    ports:
      - "{{PORT_REDIS}}:6379"
    networks:
      - shenma

  postgres:
    image: postgres:15-alpine
    restart: always
    environment:
      TZ: "Asia/Shanghai"
      POSTGRES_DB: "keycloak"
      POSTGRES_USER: "keycloak"
      POSTGRES_PASSWORD: "{{PASSWORD_POSTGRES}}"
    volumes:
      - ./postgres/data:/var/lib/postgresql/data
    ports:
      - "{{PORT_POSTGRES}}:5432/tcp"
    networks:
      - shenma

  keycloak:
    image: quay.io/keycloak/keycloak:20.0.5
    command: ["start-dev"]
    restart: always
    environment:
      TZ: "Asia/Shanghai"
      DB_ADDR: "{{ZGSM_BACKEND}}"
      DB_PORT: "{{PORT_POSTGRES}}"
      DB_VENDOR: "postgres"
      KEYCLOAK_ADMIN: "admin"
      KEYCLOAK_ADMIN_PASSWORD: "{{PASSWORD_KEYCLOAK}}"
    ports:
      - "{{PORT_KEYCLOAK}}:8080/tcp"
    volumes:
      - ./keycloak/providers:/opt/keycloak/providers
      - ./keycloak/keycloak.conf:/opt/keycloak/conf/keycloak.conf:ro
    depends_on:
      - postgres
    networks:
      - shenma
    
  portal:
    image: nginx:1.27.1
    restart: always
    environment:
      TZ: "Asia/Shanghai"
    volumes:
      - ./portal/data:/var/www
      - ./portal/nginx.conf:/etc/nginx/nginx.conf
    ports:
      - "{{PORT_PORTAL}}:80/tcp"
    networks:
      - shenma

  trampoline:
    image: trampoline:1.0.241018
    restart: always
    environment:
      TZ: "Asia/Shanghai"
    volumes:
      - ./trampoline/data:/opt/trampoline/resources
    ports:
      - "{{PORT_TRAMPOLINE}}:8080/tcp"
    networks:
      - shenma

  kaptcha:
    image: kaptcha-generator:v0.6.0
    restart: always
    working_dir: /root/kaptcha
    volumes:
      - ./kaptcha/application.yaml:/root/kaptcha/application.yaml
    environment:
      TZ: "Asia/Shanghai"
      SPRING_CONFIG_LOCATION: "/root/kaptcha/application.yaml"
    ports:
      - "9696:9696/tcp"
    networks:
      - shenma

  chatgpt-initdb:
    image: docker.sangfor.com/containerd/chat-server:1.2.0
    command: ["/sbin/entrypoint.sh", "app:init"]
    restart: no
    profiles:
      - initdb
    volumes:
      - ./chatgpt/server:/server
      - ./chatgpt/supervisor:/var/log/supervisor
      - ./chatgpt/logs:/server/logs
    ports:
      - "{{PORT_CHATGPT_API}}:5000/tcp"
      - "{{PORT_CHATGPT_WS}}:8765/tcp"
      - "5555:5555/tcp"
    environment:
      - TZ=Asia/Shanghai
      - CACHE_DB=chatgpt
      - REDIS_URL=redis://{{ZGSM_BACKEND}}:{{PORT_REDIS}}/0
      - SERVE_THREADS=200
      - SERVE_CONNECTION_LIMIT=512
      - PG_URL={{ZGSM_BACKEND}}:{{PORT_POSTGRES}}
      - DB_NAME=chatgpt
      - DATABASE_URI=postgresext+pool://keycloak:{{PASSWORD_POSTGRES}}@{{ZGSM_BACKEND}}/chatgpt
      - ES_SERVER=http://{{ZGSM_BACKEND}}:{{PORT_ES}}
      - ES_PASSWORD={{PASSWORD_ELASTIC}}
      - DEVOPS_URL=
      - GEVENT_SUPPORT=True
      - NO_COLOR=1
      - DEPLOYMENT_TYPE=all
    depends_on:
      - redis
      - postgres
    networks:
      - shenma

  chatgpt:
    image: docker.sangfor.com/containerd/chat-server:1.2.0
    command: ["/sbin/entrypoint.sh", "app:start"]
    restart: always
    volumes:
      - ./chatgpt/server:/server
      - ./chatgpt/supervisor:/var/log/supervisor
      - ./chatgpt/logs:/server/logs
    ports:
      - "{{PORT_CHATGPT_API}}:5000/tcp"
      - "{{PORT_CHATGPT_WS}}:8765/tcp"
      - "5555:5555/tcp"
    environment:
      - TZ=Asia/Shanghai
      - CACHE_DB=chatgpt
      - REDIS_URL=redis://{{ZGSM_BACKEND}}:{{PORT_REDIS}}/0
      - SERVE_THREADS=200
      - SERVE_CONNECTION_LIMIT=512
      - PG_URL={{ZGSM_BACKEND}}:{{PORT_POSTGRES}}
      - DB_NAME=chatgpt
      - DATABASE_URI=postgresext+pool://keycloak:{{PASSWORD_POSTGRES}}@{{ZGSM_BACKEND}}/chatgpt
      - ES_SERVER=http://{{ZGSM_BACKEND}}:{{PORT_ES}}
      - ES_PASSWORD={{PASSWORD_ELASTIC}}
      - DEVOPS_URL=
      - GEVENT_SUPPORT=True
      - NO_COLOR=1
      - DEPLOYMENT_TYPE=all
    depends_on:
      - redis
      - postgres
    networks:
      - shenma

  fauxpilot:
    # image: docker.sangfor.com/moyix/copilot_proxy:1.5.9
    image: docker.sangfor.com/moyix/copilot_proxy:1.5.15
    command: ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]
    restart: always
    volumes:
      - ./fauxpilot/logs:/python-docker/logs
      - ./fauxpilot/common-v1.5.15.py:/python-docker/utils/common.py
    ports:
      - "{{PORT_FAUXPILOT}}:5000/tcp"
    environment:
      - TZ=Asia/Shanghai
      - THRESHOLD_SCORE=0.3
      - STR_PATTERN=import +.*|from +.*|from +.* import *.*
      - USER_CODE_UPLOAD_DELAY=30
      - MAX_MODEL_COST_TIME=3000
      - CONTEXT_LINES_LIMIT=1000
      - SNIPPET_TOP_N=0
      - MAX_MODEL_LEN=4000,2000
      - MAX_TOKENS=500
      - MULTI_LINE_STREAM_K=6
      - ENABLE_REDIS=False
      - REDIS_HOST={{ZGSM_BACKEND}}
      - REDIS_PORT={{PORT_REDIS}}
      - REDIS_DB=0
      - REDIS_PWD="{{PASSWORD_REDIS}}"
      - MAIN_MODEL_TYPE=openai
      - OPENAI_MODEL_HOST={{OPENAI_MODEL_HOST}}
      - OPENAI_MODEL={{OPENAI_MODEL}}
    depends_on:
      - redis
    networks:
      - shenma

  prometheus:
    image: quay.io/prometheus/prometheus:v2.54.0
    restart: always
    environment:
      TZ: "Asia/Shanghai"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "{{PORT_PROMETHEUS}}:9090"
    networks:
      - shenma

  grafana:
    image: docker.io/grafana/grafana:11.2.0
    restart: always
    environment:
      TZ: "Asia/Shanghai"
    ports:
      - "{{PORT_GRAFANA}}:3000"
    volumes:
      - "./grafana/provisioning:/etc/grafana/provisioning"
      - "./grafana/dashboards:/var/lib/grafana/dashboards"
      - "./grafana/config/grafana.ini:/etc/grafana/grafana.ini"
    networks:
      - shenma

  es:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.9.0
    environment:
      - TZ=Asia/Shanghai
      - discovery.type=single-node
      - bootstrap.memory_lock=true
      - xpack.security.enabled=false  # 禁用安全功能
      - xpack.security.http.ssl.enabled=false  # 禁用 HTTPS
      - xpack.ml.enabled=false
      - "ELASTIC_PASSWORD={{PASSWORD_ELASTIC}}"
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    user: "1000:1000"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    ports:
      - "{{PORT_ES}}:9200"
      - "9300:9300"
    volumes:
      - ./es/data:/usr/share/elasticsearch/data
    networks:
      - shenma

  kibana:
    image: docker.elastic.co/kibana/kibana:8.9.0
    environment:
      - ELASTICSEARCH_HOSTS=http://{{ZGSM_BACKEND}}:{{PORT_ES}}  # 指向 Elasticsearch
      - ELASTICSEARCH_USERNAME=elastic  # Elasticsearch 用户名
      - ELASTICSEARCH_PASSWORD={{PASSWORD_ELASTIC}}  # Elasticsearch 密码
    ports:
      - "5601:5601"  # Kibana 端口
    depends_on:
      - es
    networks:
      - shenma

networks:
  shenma:
    driver: bridge

