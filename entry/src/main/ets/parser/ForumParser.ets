import type { Category, CategorySub, BoardContent } from '../model/Forum';

export function parseForumCategories(raw: object | null): Category[] {
  const categories: Category[] = [];
  if (!raw) return categories;

  const rawObj = raw as Record<string, Object>;
  const result = rawObj['result'];
  if (!result || typeof result !== 'object') return categories;

  const resultRecord = result as Record<string, Object>;
  const keys = Object.keys(resultRecord);
  for (let i = 0; i < keys.length; i++) {
    const cat = resultRecord[keys[i]] as Record<string, Object>;
    const category: Category = {
      id: String(cat['_id'] ?? cat['id'] ?? ''),
      name: String(cat['name'] ?? ''),
      sub: parseGroups(cat['groups']),
    };
    categories.push(category);
  }
  return categories;
}

function parseGroups(groups: Object | undefined): CategorySub[] {
  const result: CategorySub[] = [];
  if (!Array.isArray(groups)) return result;

  const arr = groups as Array<Object>;
  for (let i = 0; i < arr.length; i++) {
    const g = arr[i] as Record<string, Object>;
    const sub: CategorySub = {
      name: String(g['name'] ?? ''),
      content: parseForums(g['forums']),
    };
    result.push(sub);
  }
  return result;
}

function parseForums(forums: Object | undefined): BoardContent[] {
  const result: BoardContent[] = [];
  if (!Array.isArray(forums)) return result;

  const arr = forums as Array<Object>;
  for (let i = 0; i < arr.length; i++) {
    const f = arr[i] as Record<string, Object>;
    const board: BoardContent = {
      fid: Number(f['fid']) || 0,
      stid: Number(f['id']) || 0,
      name: String(f['name'] ?? ''),
      info: String(f['info'] ?? ''),
      nameS: String(f['name'] ?? ''),
      infoS: String(f['info'] ?? ''),
      head: String(f['icon'] ?? ''),
      bit: f['bit'] as number | undefined,
    };
    result.push(board);
  }
  return result;
}
