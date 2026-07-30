import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    // 支持两种测试文件：
    // *.test.ts - 单元测试（默认，使用 MSW Mock）
    // *.integration.test.ts - 集成测试（连真实后端）
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    exclude: ['**/*.integration.test.ts', '**/*.integration.spec.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        'src/test/**',
        'src/types/**',
        'src/vite-env.d.ts',
        'src/main.tsx',
        '**/*.d.ts',
      ],
    },
    // 模拟静态资源
    mockReset: false,
    restoreMocks: false,
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
