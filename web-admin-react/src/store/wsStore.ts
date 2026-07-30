import { create } from 'zustand';

interface WSState {
  ws: WebSocket | null;
  connected: boolean;
  reconnectAttempts: number;
  latestVitals: Record<string, Record<string, number>>;
  deviceOnline: Record<string, boolean>;
  newAlarms: number;          // 未读报警数
  lastAlarmData: any | null;   // 最新报警详情
  signinNotify: any | null;    // 最新签到通知
  connect: (token: string) => void;
  disconnect: () => void;
}

// 自动重连配置
const MAX_RECONNECT_ATTEMPTS = 10;
const RECONNECT_BASE_DELAY = 2000; // 首次重连 2s，指数退避

// 防止重复连接的锁
let isConnecting = false;

// 获取最新 token（从 localStorage）
function getLatestToken(): string | null {
  return localStorage.getItem('access_token');
}

export const useWSStore = create<WSState>((set, get) => ({
  ws: null,
  connected: false,
  reconnectAttempts: 0,
  latestVitals: {},
  deviceOnline: {},
  newAlarms: 0,
  lastAlarmData: null,
  signinNotify: null,

  connect: (token: string) => {
    const { ws: existing } = get();

    // 如果已有连接且处于 OPEN 状态，不重复连接
    if (existing && existing.readyState === WebSocket.OPEN) {
      console.log('[WS] Already connected (OPEN), skipping duplicate connect');
      return;
    }

    // 防止并发触发多次连接（如 React StrictMode 双重调用）
    if (isConnecting) {
      console.log('[WS] Connect already in progress, skipping duplicate call');
      return;
    }
    isConnecting = true;

    // 关闭旧连接（残留的非 OPEN 状态）
    if (existing && existing.readyState !== WebSocket.CLOSED) {
      console.log('[WS] Closing stale connection, readyState:', existing.readyState);
      existing.close(4000, 'Replacing with new connection');
    }

    let wsUrl: string;
    const envWsUrl = import.meta.env.VITE_WS_URL;
    if (envWsUrl) {
      wsUrl = `${envWsUrl}?token=${token}`;
    } else {
      const protocol = location.protocol === 'https:' ? 'wss' : 'ws';
      wsUrl = `${protocol}://${location.host}/ws?token=${token}`;
    }

    console.log('[WS] Connecting to:', wsUrl.replace(/token=.*/, 'token=***'));

    const ws = new WebSocket(wsUrl);

    ws.onopen = () => {
      isConnecting = false;
      console.log('[WS] Connected ✓');
      set({ connected: true, reconnectAttempts: 0 });

      // 连接成功后订阅所有事件
      ws.send(JSON.stringify({
        action: 'subscribe',
        topics: ['global', 'devices', 'alarms', 'vitals', 'signins'],
      }));
    };

    ws.onclose = (event) => {
      isConnecting = false;
      console.log(`[WS] Disconnected (code=${event.code}, reason="${event.reason || ''}")`);
      set({ connected: false });

      // 自动重连（非主动断开时）
      const { reconnectAttempts } = get();
      if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS && event.code !== 1000 && event.code !== 4000) {
        const delay = Math.min(RECONNECT_BASE_DELAY * Math.pow(2, reconnectAttempts), 30000);
        console.log(`[WS] Reconnecting in ${delay}ms... (attempt ${reconnectAttempts + 1}/${MAX_RECONNECT_ATTEMPTS})`);
        set({ reconnectAttempts: reconnectAttempts + 1 });
        setTimeout(() => {
          // ★ 关键修复：每次重连都从 localStorage 获取最新的 token
          // 而不是用闭包中可能已过期的旧 token
          const latestToken = getLatestToken();
          if (latestToken) {
            console.log('[WS] Reconnecting with fresh token from localStorage');
            get().connect(latestToken);
          } else {
            console.warn('[WS] No token available for reconnect, giving up');
          }
        }, delay);
      } else if (event.code === 1000 || event.code === 4000) {
        console.log('[WS] Normal disconnect, not reconnecting');
      } else {
        console.error('[WS] Max reconnect attempts reached or stopped by user');
      }
    };

    ws.onerror = (err) => {
      isConnecting = false;
      console.error('[WS] Error', err);
      set({ connected: false });
    };

    ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data);
        switch (msg.type) {
          case 'vital_update':
            console.log('[WS] vital_update:', msg.data);
            if (msg.data?.elderly_id) {
              set((s) => ({
                latestVitals: {
                  ...s.latestVitals,
                  [msg.data.elderly_id]: {
                    heart_rate: msg.data.heart_rate ?? '-',
                    spo2: msg.data.spo2 ?? '-',
                    temperature: msg.data.temperature ?? '-',
                    steps: msg.data.steps ?? 0,
                  },
                },
              }));
            }
            break;

          case 'new_alarm':
            console.log('[WS] new_alarm:', msg.data);
            set((s) => ({
              newAlarms: s.newAlarms + 1,
              lastAlarmData: msg.data,
            }));

            // 浏览器通知
            if ('Notification' in window && Notification.permission === 'granted') {
              const severity = msg.data?.severity || 'P2';
              new Notification(`🚨 ${severity} 级报警`, {
                body: `设备 ${msg.data?.device_sn} 触发 ${msg.data?.alarm_type} 报警`,
                tag: `alarm-${Date.now()}`,
              });
            }
            break;

          case 'device_online':
            console.log('[WS] device_online:', msg.data);
            if (msg.data?.device_sn) {
              set((s) => ({
                deviceOnline: {
                  ...s.deviceOnline,
                  [msg.data.device_sn]: true,
                },
              }));
            }
            break;

          case 'heartbeat':
            // 心跳消息用于更新设备状态，可触发页面局部刷新
            if (msg.data?.device_sn) {
              set((s) => ({
                deviceOnline: {
                  ...s.deviceOnline,
                  [msg.data.device_sn]: true,
                },
              }));
            }
            break;

          case 'signin_notify':
            console.log('[WS] signin_notify:', msg.data);
            set({ signinNotify: msg.data });
            break;

          case 'dashboard_refresh':
            console.log('[WS] dashboard_refresh');
            window.dispatchEvent(new CustomEvent('ws:dashboard_refresh', { detail: msg.data }));
            break;

          case 'subscribed':
            console.log('[WS] Subscribed to topics:', msg.data);
            break;

          default:
            console.log('[WS] Unknown message type:', msg.type, msg);
        }

        // 全局事件派发，让页面组件可以监听
        window.dispatchEvent(new CustomEvent('ws:message', { detail: msg }));
      } catch (e) {
        console.warn('[WS] Failed to parse message:', e);
      }
    };

    set({ ws });
  },

  disconnect: () => {
    const { ws } = get();
    if (ws) {
      ws.close(1000); // 正常关闭
      isConnecting = false;
      set({ ws: null, connected: false, reconnectAttempts: MAX_RECONNECT_ATTEMPTS + 1 });
    }
  },

  // 重置未读报警数（查看报警列表后调用）
  resetNewAlarms: () => set({ newAlarms: 0 }),
}));
