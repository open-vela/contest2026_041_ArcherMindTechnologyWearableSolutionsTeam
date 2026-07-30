# ============================================================
# AI 老年健康守护系统 - 前端管理台 Docker 镜像
# 多阶段构建：Node 构建 → Nginx 运行
# ============================================================

# ---- Stage 1: 构建阶段 ----
FROM node:22-alpine AS builder

WORKDIR /app

# 利用 Docker 层缓存：先复制依赖文件
COPY package.json package-lock.json ./

# 安装依赖：先忽略 postinstall 脚本避免 esbuild 的 ETXTBSY 错误，再单独初始化
RUN npm ci --legacy-peer-deps --ignore-scripts
RUN node ./node_modules/esbuild/install.js

# 复制全部源码
COPY . .

# 构建生产版本
# ARG 可在 docker build 时传入：--build-arg VITE_API_BASE_URL=https://api.example.com/api/v1
ARG VITE_API_BASE_URL=/api/v1
ARG VITE_WS_URL=ws://localhost/ws
ARG VITE_APP_TITLE=AI老年健康守护系统

ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
ENV VITE_WS_URL=$VITE_WS_URL
ENV VITE_APP_TITLE=$VITE_APP_TITLE

# 用 node 直接执行 JS 文件，避开 Alpine npm symlink 的 +x 权限问题
RUN node ./node_modules/vite/bin/vite.js build

# ---- Stage 2: 运行阶段 ----
FROM nginx:1.25-alpine

# 安装 wget 用于健康检查
RUN apk add --no-cache wget

# 复制自定义 Nginx 配置
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 创建非 root 用户运行 Nginx（安全最佳实践）
RUN addgroup -g 1001 -S nginxgroup \
    && adduser -S nginxuser -u 1001 -G nginxgroup \
    && chown -R nginxuser:nginxgroup /usr/share/nginx/html \
    && chown -R nginxuser:nginxgroup /var/cache/nginx \
    && chown -R nginxuser:nginxgroup /var/log/nginx \
    && chown -R nginxuser:nginxgroup /etc/nginx/conf.d \
    && touch /var/run/nginx.pid \
    && chown -R nginxuser:nginxgroup /var/run/nginx.pid

USER nginxuser

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
