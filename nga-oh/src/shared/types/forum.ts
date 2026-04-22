export interface ForumInfo {
  fid: number;
  name: string;
  info?: string;
}

export interface Category {
  id: string;
  name: string;
  sub: CategorySub[];
}

export interface CategorySub {
  name: string;
  content: BoardContent[];
}

export interface BoardContent {
  fid: number;
  stid: number;
  name: string;
  info: string;
  nameS: string;
  infoS: string;
  head: string;
  bit?: number;
}
