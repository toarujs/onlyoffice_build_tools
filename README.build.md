# ONLYOFFICE DocumentServer 编译打包指南

本文档说明如何使用本仓库编译 OnlyOffice DocumentServer 并打包为完整的 Docker 镜像。

## 文件说明

| 文件 | 说明 |
|------|------|
| `Dockerfile.build` | 编译环境镜像 |
| `Dockerfile.documentserver` | DocumentServer 运行时镜像（完整版） |
| `build_and_package.sh` | 打包脚本 |
| `patch_source.sh` | 源码修改脚本 |
| `run-document-server.sh` | 容器启动脚本 |
| `docker-compose.yml` | Docker Compose 部署配置 |

## 配置目录

| 目录 | 说明 |
|------|------|
| `config/nginx/` | Nginx 配置 |
| `config/supervisor/` | Supervisor 配置 |
| `config/logrotate/` | 日志轮转配置 |
| `fonts/` | 字体文件 |

## 快速开始

### 方式一：分步执行

#### 1. 构建编译环境镜像

```bash
docker build -f Dockerfile.build -t onlyoffice-build:latest .
```

#### 2. 运行编译容器

```bash
docker run -d --name onlyoffice-build \
  -v onlyoffice-build-data:/build_output \
  onlyoffice-build:latest
```

#### 3. 等待编译完成

```bash
# 查看日志
docker logs -f onlyoffice-build

# 等待完成（约需 2-4 小时）
docker wait onlyoffice-build
```

#### 4. 修改源码（可选）

在编译完成后、构建镜像前，修改源码：

```bash
docker exec -it onlyoffice-build bash
cd /build_tools
./scripts/patch_source.sh
exit
```

#### 5. 打包构建 DocumentServer 镜像

```bash
# 复制编译产物
docker cp onlyoffice-build:/build_output/onlyoffice ./output/package/

# 构建镜像
docker build -f Dockerfile.documentserver -t onlyoffice-documentserver:custom ./output/package/
```

#### 6. 运行

```bash
docker run -d -p 80:80 -p 443:443 onlyoffice-documentserver:custom
```

### 方式二：使用 docker-compose

```bash
# 1. 先编译（修改 build_and_package.sh 中的 OUTPUT_DIR）
./build_and_package.sh

# 2. 使用 docker-compose 启动
docker-compose up -d
```

## 完整组件说明

构建的镜像包含以下组件：

| 组件 | 说明 |
|------|------|
| PostgreSQL | 数据库 |
| Redis | 缓存（Enterprise 功能） |
| RabbitMQ | 消息队列（Enterprise 功能） |
| Nginx | Web 服务器 |
| Supervisor | 进程管理 |
| Python3 | 服务运行环境 |
| Fonts | 微软核心字体 |

## 源码修改

`patch_source.sh` 脚本会进行以下修改：

1. **连接数修改** - 将 `LICENSE_CONNECTIONS` 改为 2000
2. **开启 advancedApi** - 设置 `advancedApi: true`
3. **QT 镜像地址** - 使用国内镜像加速下载
4. **添加 connector.api 方法** - 添加 `historyTurnOff`/`historyTurnOn`
5. **关闭源码更新** - 设置 `--update 0`

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `COMPANY_NAME` | onlyoffice | 公司名称 |
| `PRODUCT_NAME` | documentserver | 产品名称 |
| `DS_DOCKER_INSTALLATION` | true | Docker 安装标识 |

## 数据持久化

镜像使用以下 Volume：

| Volume | 路径 |
|--------|------|
| documentserver-data | /var/www/onlyoffice/Data |
| documentserver-logs | /var/log/onlyoffice |
| documentserver-postgres | /var/lib/postgresql |
| documentserver-rabbitmq | /var/lib/rabbitmq |
| documentserver-redis | /var/lib/redis |
| documentserver-fonts | /usr/share/fonts/truetype/custom |

## 验证安装

```bash
# 检查容器状态
docker ps

# 查看日志
docker logs onlyoffice-documentserver

# 测试服务
curl -k https://localhost/healthcheck
curl -k http://localhost/
```

## 与官方版对比

| 功能 | 自编译版 | 官方版 |
|------|---------|--------|
| 核心编辑器 | ✅ | ✅ |
| PostgreSQL | ✅ | ✅ |
| Redis | ✅ | ✅ |
| RabbitMQ | ✅ | ✅ |
| AdminPanel | ❌ | ✅ (Enterprise) |
| Oracle 支持 | ✅ | ✅ |
| 商业支持 | ❌ | ✅ (付费) |

## 注意事项

1. 编译需要较长时间（2-4 小时），请确保网络稳定
2. 需要约 50GB+ 磁盘空间
3. 建议在具有足够资源的机器上编译

## 故障排查

### 编译失败

```bash
docker run -it --entrypoint bash onlyoffice-build:latest
cd /build_tools/tools/linux
./automate.py server --update=0
```

### 镜像启动失败

```bash
docker run -it onlyoffice-documentserver:custom /bin/bash
/app/ds/run-document-server.sh
```
