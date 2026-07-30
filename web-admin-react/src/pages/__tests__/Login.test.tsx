/**
 * Login 页面组件测试
 */
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { BrowserRouter } from 'react-router-dom';
import Login from '../Login';

// 先 mock，再 import
vi.mock('@/store/authStore', async () => {
  const actual = await vi.importActual('@/store/authStore') as any;
  return {
    useAuthStore: vi.fn(),
  };
});

import { useAuthStore } from '@/store/authStore';

// 包装组件辅助函数
function renderLogin() {
  return render(
    <BrowserRouter>
      <Login />
    </BrowserRouter>,
  );
}

describe('Login 页面', () => {
  const mockLogin = vi.fn();

  beforeEach(() => {
    // 每次测试前设置 mock 返回值
    (useAuthStore as any).mockReturnValue({
      login: mockLogin,
    });
    mockLogin.mockClear();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('渲染系统标题', () => {
    renderLogin();
    expect(screen.getByText('AI 老年健康守护系统')).toBeInTheDocument();
  });

  it('渲染演示账号信息', () => {
    renderLogin();
    expect(screen.getByText(/演示账号/)).toBeInTheDocument();
  });

  it('渲染用户名输入框', () => {
    renderLogin();
    // antd Input 的 placeholder 在 input 元素上
    const input = document.querySelector('input[placeholder="用户名"]');
    expect(input).toBeInTheDocument();
  });

  it('渲染密码输入框', () => {
    renderLogin();
    const input = document.querySelector('input[placeholder="密码"]');
    expect(input).toBeInTheDocument();
  });

  it('渲染登录按钮', () => {
    renderLogin();
    // antd Button 文本是 "登 录"（带空格）
    expect(screen.getByText(/登.*录/)).toBeInTheDocument();
  });

  it('提交正确凭证调用 login 方法', async () => {
    mockLogin.mockResolvedValueOnce(undefined);

    renderLogin();

    const usernameInput = document.querySelector('input[placeholder="用户名"]') as HTMLInputElement;
    const passwordInput = document.querySelector('input[placeholder="密码"]') as HTMLInputElement;
    const submitButton = screen.getByText(/登.*录/);

    await userEvent.clear(usernameInput);
    await userEvent.type(usernameInput, 'admin');
    await userEvent.clear(passwordInput);
    await userEvent.type(passwordInput, 'Admin@2026');
    await userEvent.click(submitButton);

    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith('admin', 'Admin@2026');
    });
  });
});
