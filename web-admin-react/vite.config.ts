import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  // API 代理目标：从环境变量读取，默认 localhost:80
  const proxyTarget = env.VITE_PROXY_TARGET || 'http://localhost:80';

  return {
    plugins: [react()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      },
    },
    server: {
      port: 5173,
      proxy: {
        '/api': {
          target: proxyTarget,
          changeOrigin: true,
          ws: true,
        },
        '/ws': {
          target: proxyTarget,
          changeOrigin: true,
          ws: true,
        },
      },
    },
    build: {
      // 输出目录
      outDir: 'dist',
      // 启用 sourcemap（可选，调试用）
      sourcemap: mode !== 'production',
      // chunk 大小警告阈值
      chunkSizeWarningLimit: 1000,
      rollupOptions: {
        output: {
          // 手动分包策略
          manualChunks: {
            // React 核心
            'react-vendor': ['react', 'react-dom', 'react-router-dom'],
            // Ant Design
            'antd-vendor': ['antd', '@ant-design/icons'],
            // 图表库
            'chart-vendor': ['recharts'],
            // 工具库
            'util-vendor': ['axios', 'dayjs', 'zustand'],
          },
        },
      },
    },
  };
});
