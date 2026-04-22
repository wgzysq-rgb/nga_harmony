import type { Category, CategorySub, BoardContent, ForumInfo } from '../types/forum.js';

export function parseForumSearch(raw: any): ForumInfo[] {
  if (!raw || typeof raw !== 'object') return [];
  if (raw.error) return [];

  const src = raw.data ?? raw.result;
  if (!src || typeof src !== 'object') return [];

  const items = Array.isArray(src) ? src : Object.values(src);

  return items
    .filter((item: any) => item && typeof item === 'object' && (item.fid || item.id))
    .map((item: any) => ({
      fid: Number(item.fid ?? item.id) || 0,
      name: String(item.name ?? ''),
      ...(item.info ? { info: String(item.info) } : {}),
    }))
    .filter((f: ForumInfo) => f.fid > 0);
}

export function parseForumCategories(raw: any): Category[] {
  // raw 是 NGA app_api.php 的完整响应，分类数据在 result 字段中
  const result = raw?.result;
  if (!result || typeof result !== 'object') return [];

  // result 是对象，key 为 "0"-"6"，每个值是一个分类组
  return Object.values(result).map((cat: any) => ({
    id: String(cat._id ?? cat.id ?? ''),
    name: cat.name ?? '',
    sub: parseGroups(cat.groups),
  }));
}

function parseGroups(groups: any): CategorySub[] {
  if (!Array.isArray(groups)) return [];

  return groups.map((g: any) => ({
    name: g.name ?? '',
    content: parseForums(g.forums),
  }));
}

function parseForums(forums: any): BoardContent[] {
  if (!Array.isArray(forums)) return [];

  return forums.map((f: any) => ({
    fid: Number(f.fid) || 0,
    stid: Number(f.id) || 0,
    name: f.name ?? '',
    info: f.info ?? '',
    nameS: f.name ?? '',
    infoS: f.info ?? '',
    head: f.icon ?? '',
    bit: f.bit,
  }));
}
