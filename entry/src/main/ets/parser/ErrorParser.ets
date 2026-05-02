export function parseNgaError(data: object | null): string | null {
  if (!data) return null;
  const d = data as Record<string, Object>;
  if (d['error']) {
    if (typeof d['error'] !== 'string') {
      const errorObj = d['error'] as Record<string, Object>;
      const rawCode = errorObj['2'];
      if (rawCode === 0 || rawCode === '0') {
        return null;
      }
      return String(errorObj['0'] ?? '未知错误');
    }
    return String(d['error']);
  }
  if (d['error_code']) {
    const code = Number(d['error_code']);
    const codes: Record<number, string> = {
      9: '附件过大',
      10: '权限不足',
      11: '未登录',
      12: '内容为空',
      13: '验证码错误',
      14: '用户名或密码错误',
      15: '频率限制',
    };
    return codes[code] ?? `错误码: ${code}`;
  }
  return null;
}
