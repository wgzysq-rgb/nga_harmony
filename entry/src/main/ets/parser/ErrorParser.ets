export function parseNgaError(data: object | null): string | null {
  if (!data) return null;
  const d = data as Record<string, Object>;
  if (d['error']) {
    return typeof d['error'] === 'string' ? String(d['error']) :
      (String((d['error'] as Record<string, Object>)['0'] ?? '未知错误'));
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
