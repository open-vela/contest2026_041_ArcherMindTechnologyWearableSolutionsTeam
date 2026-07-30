/**
 * wsStore 单元测试
 * 测试 WebSocket 连接状态管理
 */
import { describe, it, expect, beforeAll, afterAll, afterEach } from 'vitest';
import { useWSStore } from '../wsStore';

describe('wsStore - 初始状态', () => {
  afterEach(() => {
    useWSStore.getState().disconnect();
    useWSStore.setState({
      ws: null,
      connected: false,
      latestVitals: {},
      newAlarms: 0,
    });
  });

  it('初始未连接状态', () => {
    const state = useWSStore.getState();
    expect(state.connected).toBe(false);
    expect(state.ws).toBeNull();
    expect(state.newAlarms).toBe(0);
  });
});

describe('wsStore - 连接管理', () => {
  it('connect 建立连接后 connected 为 true', async () => {
    const { connect } = useWSStore.getState();

    // Mock WebSocket（已在 setup.ts 中全局 mock）
    connect('mock_token');

    // 等待 MockWebSocket 模拟异步连接
    await new Promise((r) => setTimeout(r, 50));

    const state = useWSStore.getState();
    expect(state.connected).toBe(true);
    expect(state.ws).not.toBeNull();
  });

  it('disconnect 断开连接后 connected 为 false', async () => {
    const { connect, disconnect } = useWSStore.getState();

    connect('mock_token');
    await new Promise((r) => setTimeout(r, 50));

    disconnect();

    const state = useWSStore.getState();
    expect(state.connected).toBe(false);
    expect(state.ws).toBeNull();
  });
});

describe('wsStore - 消息处理', () => {
  it('收到 vital_update 消息后更新 latestVitals', async () => {
    const { connect } = useWSStore.getState();

    connect('mock_token');
    await new Promise((r) => setTimeout(r, 50));

    // 获取 MockWebSocket 实例并模拟收到消息
    const MockWebSocket = (global as any).WebSocket;
    const wsInstance = MockWebSocket.instances[0];

    if (wsInstance) {
      wsInstance.simulateMessage({
        type: 'vital_update',
        elderly_id: 'e001',
        data: { heart_rate: 75, blood_oxygen: 97 },
      });

      const state = useWSStore.getState();
      expect(state.latestVitals['e001']).toBeDefined();
      expect(state.latestVitals['e001']['heart_rate']).toBe(75);
    }
  });

  it('收到 new_alarm 消息后 newAlarms 计数 +1', async () => {
    const { connect } = useWSStore.getState();

    connect('mock_token');
    await new Promise((r) => setTimeout(r, 50));

    const MockWebSocket = (global as any).WebSocket;
    const wsInstance = MockWebSocket.instances[0];

    if (wsInstance) {
      const before = useWSStore.getState().newAlarms;
      wsInstance.simulateMessage({ type: 'new_alarm' });
      expect(useWSStore.getState().newAlarms).toBe(before + 1);
    }
  });
});
