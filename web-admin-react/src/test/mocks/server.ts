/**
 * MSW Server 设置
 * 用于启动/关闭 Mock API 服务
 */
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

// 创建 MSW server 实例
export const server = setupServer(...handlers);

// 导出辅助函数：动态覆盖指定接口的处理逻辑
export function overrideHandler(method: string, path: string, resolver: any) {
  server.use(
    // 使用 http[method.toLowerCase()] 动态覆盖
    (handlers.find(
      (h: any) => h.info.method === method.toUpperCase() && h.info.path === path,
    ) ?? http[method as any](path, resolver)) as any,
  );
}
