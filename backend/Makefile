.PHONY: help build run test clean docker-up docker-down docker-build db-init db-seed

# 默认目标
.DEFAULT_GOAL := help

help: ## 显示帮助信息
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ============ 构建 ============
build: build-user build-device build-alarm build-signin build-admin-auth build-dashboard build-patrol build-report ## 构建所有服务

build-user: ## 构建用户服务
	@echo "Building user-service..."
	go build -ldflags="-s -w" -o bin/user-service ./cmd/user-service

build-device: ## 构建设备服务
	@echo "Building device-service..."
	go build -ldflags="-s -w" -o bin/device-service ./cmd/device-service

build-alarm: ## 构建报警服务
	@echo "Building alarm-service..."
	go build -ldflags="-s -w" -o bin/alarm-service ./cmd/alarm-service

build-signin: ## 构建签到服务
	@echo "Building signin-service..."
	go build -ldflags="-s -w" -o bin/signin-service ./cmd/signin-service

build-admin-auth: ## 构建管理员认证服务
	@echo "Building admin-auth-service..."
	go build -ldflags="-s -w" -o bin/admin-auth-service ./cmd/admin-auth-service

build-dashboard: ## 构建看板服务
	@echo "Building dashboard-service..."
	go build -ldflags="-s -w" -o bin/dashboard-service ./cmd/dashboard-service

build-patrol: ## 构建巡访服务
	@echo "Building patrol-service..."
	go build -ldflags="-s -w" -o bin/patrol-service ./cmd/patrol-service

build-report: ## 构建周报服务
	@echo "Building report-service..."
	go build -ldflags="-s -w" -o bin/report-service ./cmd/report-service

# ============ 运行 ============
run-user: ## 运行用户服务
	go run ./cmd/user-service

run-device: ## 运行设备服务
	go run ./cmd/device-service

run-alarm: ## 运行报警服务
	go run ./cmd/alarm-service

run-signin: ## 运行签到服务
	go run ./cmd/signin-service

run-admin-auth: ## 运行管理员认证服务
	go run ./cmd/admin-auth-service

run-dashboard: ## 运行看板服务
	go run ./cmd/dashboard-service

run-patrol: ## 运行巡访服务
	go run ./cmd/patrol-service

run-report: ## 运行周报服务
	go run ./cmd/report-service

# ============ 测试 ============
test: ## 运行所有测试
	go test ./... -v -cover

test-race: ## 运行竞态检测测试
	go test ./... -race -v

# ============ 代码质量 ============
lint: ## 代码检查
	golangci-lint run ./...

fmt: ## 格式化代码
	go fmt ./...

vet: ## 静态分析
	go vet ./...

# ============ 数据库 ============
db-init: ## 初始化数据库
	mysql -h localhost -u root -p < migrations/001_init.sql

db-migrate: ## 运行数据库迁移
	@echo "Running migrations..."
	@for f in migrations/*.sql; do \
		echo "Running $$f..."; \
		mysql -h localhost -u root -p elderly_health < $$f; \
	done

# ============ Docker ============
docker-build: ## 构建 Docker 镜像
	docker compose -f deploy/docker-compose.yml build

docker-up: ## 启动所有服务
	docker compose -f deploy/docker-compose.yml up -d

docker-down: ## 停止所有服务
	docker compose -f deploy/docker-compose.yml down

docker-logs: ## 查看所有服务日志
	docker compose -f deploy/docker-compose.yml logs -f

docker-restart: docker-down docker-up ## 重启所有服务

docker-ps: ## 查看服务状态
	docker compose -f deploy/docker-compose.yml ps

# ============ 开发辅助 ============
dev: ## 本地开发（启动基础服务）
	docker compose -f deploy/docker-compose.yml up -d mysql redis emqx
	@echo "MySQL: localhost:3306 | Redis: localhost:6379 | EMQX: localhost:1883"

dev-stop: ## 停止本地开发环境
	docker compose -f deploy/docker-compose.yml down

tidy: ## 整理 Go 依赖
	go mod tidy

vendor: ## 生成 vendor 目录
	go mod vendor

# ============ 清理 ============
clean: ## 清理构建产物
	rm -rf bin/
	@echo "Cleaned build artifacts"

clean-all: clean ## 清理所有（包括 Docker 卷）
	docker compose -f deploy/docker-compose.yml down -v
	@echo "Cleaned everything"
