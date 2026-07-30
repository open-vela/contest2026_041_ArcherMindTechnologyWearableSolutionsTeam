# ============================================================
# AI 老年健康守护系统 — Docker 多阶段构建（优化版）
# 优化策略：单个 builder 串联编译 12 个微服务
#   Go 内部编译缓存可跨服务复用，大幅缩短总构建时间
# ============================================================

# ---- Stage 1: 统一构建（编译全部 11 个微服务） ----
FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app

# 国内镜像代理
ENV GOPROXY=https://goproxy.cn,direct
# go.sum 缺失时自动补全
ENV GOFLAGS=-mod=mod
# 4核服务器用 2 个并发编译（留 2 核给其他任务）
ENV GOMAXPROCS=2
# 通用编译参数
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOARCH=amd64

# ---- 依赖缓存层 ----
COPY go.mod ./
RUN go mod download

# ---- 源码复制 ----
COPY . .

# ---- 补齐 go.sum ----
RUN go mod tidy

# ---- 统一编译 12 个微服务（同一 RUN，Go 内部缓存复用） ----
# BuildKit 挂载持久缓存，二次构建直接命中
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    mkdir -p /build && \
    echo ">>> 1/12 user-service" && \
    go build -ldflags="-s -w" -o /build/user-service ./cmd/user-service && \
    echo ">>> 2/12 device-service" && \
    go build -ldflags="-s -w" -o /build/device-service ./cmd/device-service && \
    echo ">>> 3/12 vital-service" && \
    go build -ldflags="-s -w" -o /build/vital-service ./cmd/vital-service && \
    echo ">>> 4/12 alarm-service" && \
    go build -ldflags="-s -w" -o /build/alarm-service ./cmd/alarm-service && \
    echo ">>> 5/12 signin-service" && \
    go build -ldflags="-s -w" -o /build/signin-service ./cmd/signin-service && \
    echo ">>> 6/12 admin-auth-service" && \
    go build -ldflags="-s -w" -o /build/admin-auth-service ./cmd/admin-auth-service && \
    echo ">>> 7/12 dashboard-service" && \
    go build -ldflags="-s -w" -o /build/dashboard-service ./cmd/dashboard-service && \
    echo ">>> 8/12 patrol-service" && \
    go build -ldflags="-s -w" -o /build/patrol-service ./cmd/patrol-service && \
    echo ">>> 9/12 report-service" && \
    go build -ldflags="-s -w" -o /build/report-service ./cmd/report-service && \
    echo ">>> 10/12 notify-service" && \
    go build -ldflags="-s -w" -o /build/notify-service ./cmd/notify-service && \
    echo ">>> 11/12 emergency-service" && \
    go build -ldflags="-s -w" -o /build/emergency-service ./cmd/emergency-service && \
    echo ">>> 12/12 websocket-service" && \
    go build -ldflags="-s -w" -o /build/websocket-service ./cmd/websocket-service && \
    echo ">>> All 12 services built!"

# 创建日志目录
RUN mkdir -p /app/logs

# ============================================================
# Runtime Images（基于 alpine:3.19，极简运行）
# ============================================================

# ===== user-service =====
FROM alpine:3.19 AS user-service
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /build/user-service /app/user-service
COPY configs/config.yaml /app/config.yaml
WORKDIR /app
USER 1000:1000
EXPOSE 8001
ENTRYPOINT ["./user-service"]

# ===== device-service =====
FROM alpine:3.19 AS device-service
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /build/device-service /app/device-service
COPY configs/config.yaml /app/config.yaml
WORKDIR /app
USER 1000:1000
EXPOSE 8002
ENTRYPOINT ["./device-service"]

# ===== vital-service =====
FROM alpine:3.19 AS vital-service
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /build/vital-service /app/vital-service
COPY configs/config.yaml /app/config.yaml
WORKDIR /app
USER 1000:1000
EXPOSE 8003
ENTRYPOINT ["./vital-service"]

# ===== alarm-service =====
FROM alpine:3.19 AS alarm-service
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /build/alarm-service /app/alarm-service
COPY configs/config.yaml /app/config.yaml
WORKDIR /app
USER 1000:1000
EXPOSE 8004
ENTRYPOINT ["./alarm-service"]

# ===== signin-service =====
FROM alpine:3.19 AS signin-service
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /build/signin-service /app/signin-service
COPY configs/config.yaml /app/config.yaml
WORKDIR /app
USER 1000:1000
EXPOSE 8005
ENTRYPOINT ["./signin-service"]

# ===== admin-auth-service =====
FROM alpine:3.19 AS admin-auth-service
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /build/admin-auth-service /app/admin-auth-service
COPY configs/config.yaml /app/config.yaml
WORKDIR /app
USER 1000:1000
EXPOSE 8011
ENTRYPOINT ["./admin-auth-service"]

# ===== dashboard-service =====
FROM alpine:3.19 AS dashboard-service
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /build/dashboard-service /app/dashboard-service
COPY configs/config.yaml /app/config.yaml
WORKDIR /app
USER 1000:1000
EXPOSE 8010
ENTRYPOINT ["./dashboard-service"]

# ===== patrol-service =====
FROM alpine:3.19 AS patrol-service
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /build/patrol-service /app/patrol-service
COPY configs/config.yaml /app/config.yaml
WORKDIR /app
USER 1000:1000
EXPOSE 8006
ENTRYPOINT ["./patrol-service"]

# ===== report-service =====
FROM alpine:3.19 AS report-service
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /build/report-service /app/report-service
COPY configs/config.yaml /app/config.yaml
WORKDIR /app
USER 1000:1000
EXPOSE 8008
ENTRYPOINT ["./report-service"]

# ===== notify-service =====
FROM alpine:3.19 AS notify-service
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /build/notify-service /app/notify-service
COPY configs/config.yaml /app/config.yaml
WORKDIR /app
USER 1000:1000
EXPOSE 8007
ENTRYPOINT ["./notify-service"]

# ===== emergency-service =====
FROM alpine:3.19 AS emergency-service
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /build/emergency-service /app/emergency-service
COPY configs/config.yaml /app/config.yaml
WORKDIR /app
USER 1000:1000
EXPOSE 8009
ENTRYPOINT ["./emergency-service"]

# ===== websocket-service =====
FROM alpine:3.19 AS websocket-service
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /build/websocket-service /app/websocket-service
COPY configs/config.yaml /app/config.yaml
WORKDIR /app
USER 1000:1000
EXPOSE 8012
ENTRYPOINT ["./websocket-service"]
