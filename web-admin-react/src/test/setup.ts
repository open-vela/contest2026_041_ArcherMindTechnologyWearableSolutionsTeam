/**
 * 测试环境设置文件
 * 在所有测试运行前执行，配置全局 Mock 和环境
 */
import '@testing-library/jest-dom/vitest';
import { expect, vi } from 'vitest';

// ============ 全局测试设置 ============
// 必须在导入 antd 组件之前完成所有全局 Mock

// ============ matchMedia Mock（必须在最前，antd Row/Col 依赖此 API） ============
// 使用纯函数，不用 vi.fn()，避免 restoreMocks 清除
function matchMediaImpl(_query: string) {
  return {
    matches: false,
    media: _query,
    onchange: null,
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => true,
    addListener: () => {},
    removeListener: () => {},
  };
}
(window as any).matchMedia = matchMediaImpl;

// ============ localStorage Mock ============
const localStorageStore: Record<string, string> = {};

Object.defineProperty(window, 'localStorage', {
  value: {
    getItem: vi.fn((key: string) => localStorageStore[key] ?? null),
    setItem: vi.fn((key: string, value: string) => {
      localStorageStore[key] = String(value);
    }),
    removeItem: vi.fn((key: string) => {
      delete localStorageStore[key];
    }),
    clear: vi.fn(() => {
      Object.keys(localStorageStore).forEach((k) => delete localStorageStore[k]);
    }),
    get length() {
      return Object.keys(localStorageStore).length;
    },
    key: vi.fn((index: number) => Object.keys(localStorageStore)[index] ?? null),
  },
  writable: true,
});

// ============ sessionStorage Mock ============
(window as any).sessionStorage = window.localStorage;

// ============ IntersectionObserver Mock ============
class IntersectionObserverMock {
  readonly root = null;
  readonly rootMargin = '';
  readonly thresholds: ReadonlyArray<number> = [];
  private callback: IntersectionObserverCallback;

  constructor(callback: IntersectionObserverCallback) {
    this.callback = callback;
  }
  observe() {}
  unobserve() {}
  disconnect() {}
  takeRecords() {
    return [];
  }
}
(window as any).IntersectionObserver = IntersectionObserverMock;

// ============ ResizeObserver Mock ============
class ResizeObserverMock {
  observe() {}
  unobserve() {}
  disconnect() {}
}
(window as any).ResizeObserver = ResizeObserverMock;

// ============ WebSocket Mock ============
class MockWebSocket {
  static instances: MockWebSocket[] = [];
  onopen: ((event: Event) => void) | null = null;
  onclose: ((event: CloseEvent) => void) | null = null;
  onmessage: ((event: MessageEvent) => void) | null = null;
  onerror: ((event: Event) => void) | null = null;
  readyState: number = 0; // CONNECTING
  url: string = '';
  protocol: string = '';

  constructor(url: string | URL, _protocols?: string | string[]) {
    this.url = typeof url === 'string' ? url : url.toString();
    MockWebSocket.instances.push(this);
    // 模拟异步连接成功
    setTimeout(() => {
      this.readyState = 1; // OPEN
      this.onopen?.(new Event('open'));
    }, 10);
  }

  send(_data: string): void {
    // Mock send
  }

  close(): void {
    this.readyState = 3; // CLOSED
    this.onclose?.(new CloseEvent('close'));
  }

  // 测试辅助：模拟收到消息
  simulateMessage(data: any): void {
    this.onmessage?.(new MessageEvent('message', { data: JSON.stringify(data) }));
  }
}

(global as any).WebSocket = MockWebSocket;

// ============ 清理钩子 ============
afterEach(() => {
  vi.clearAllMocks();
  // 清理 localStorage
  Object.keys(localStorageStore).forEach((k) => delete localStorageStore[k]);
  MockWebSocket.instances = [];
});
