const CLIENT_MAP: Record<string, string> = {
  '1': 'iOS',
  '7': 'iOS',
  '101': 'iOS',
  '103': 'Windows Phone',
  '9': 'Windows Phone',
  '8': 'Android',
  '100': 'Android',
};

export function parseFromClient(code: string | number | undefined): string {
  if (!code) return '';
  const key = String(code).trim();
  return CLIENT_MAP[key] ?? '';
}
