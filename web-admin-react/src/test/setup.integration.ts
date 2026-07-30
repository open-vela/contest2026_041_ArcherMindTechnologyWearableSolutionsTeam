/**
 * 集成测试 setup 文件
 * 用于连真实后端服务器进行测试
 */

import { beforeAll, afterAll } from 'vitest';
import { checkBackendHealth } from './config';

/**
 * 全局 setup：检查后端服务器是否可达
 */
beforeAll(async () => {
  console.log('\n🔍 集成测试模式：检查后端服务器...');

  const isHealthy = await checkBackendHealth();

  if (!isHealthy) {
    console.error('\n❌ 后端服务器不可达！');
    console.error('   请确认：');
    console.error('   1. 后端已启动 (docker compose up -d)');
    console.error('   2. .env.test 中 VITE_API_BASE_URL 配置正确');
    console.error('   3. 或设置 VITE_USE_MOCK=true 使用 Mock 模式\n');
    process.exit(1);
  }

  console.log('✅ 后端服务器可达\n');
});

afterAll(() => {
  console.log('\n✅ 集成测试完成\n');
});
