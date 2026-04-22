export function parseNgaError(data: any): string | null {
  if (!data) return null;
  if (data.error) {
    const msg = typeof data.error === 'string' ? data.error : (data.error['0'] ?? '未知错误');
    if (msg.startsWith(':')) return null;
    return msg;
  }
  if (data.error_code) {
    const codes: Record<number, string> = {
      9: '附件过大',
      10: '权限不足',
      11: '未登录',
      12: '内容为空',
      13: '验证码错误',
      14: '用户名或密码错误',
      15: '频率限制',
    };
    return codes[data.error_code] ?? `错误码: ${data.error_code}`;
  }
  return null;
}
