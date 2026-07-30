import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

/**
 * 集成测试配置
 * 用于连真实后端服务器进行测试
 *
 * 使用方式：
 *   npx vitest run --config vitest.integration.config.ts
 *   或 npm run test:integration
 */
export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'node', // 集成测试不需要 jsdom（直接测 API）
    include: ['src/**/*.integration.{test,spec}.{ts,tsx}'],
    exclude: ['**/node_modules/**'],

    // 集成测试不启动 MSW，直接发真实 HTTP 请求
    setupFiles: ['./src/test/setup.integration.ts'],

    // 超时时间（集成测试可能涉及网络）
    testTimeout: 15000,

    // 不模拟任何模块
    mockReset: false,
    restoreMocks: false,
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  // 加载 .env.test 环境变量
  envPrefix: ['VITE_', 'TEST_'],
});
