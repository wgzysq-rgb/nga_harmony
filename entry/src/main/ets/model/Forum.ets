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

export interface Board {
  fid: number;
  stid: number;
  name: string;
  boardHead: string;
}

export interface SubBoard extends Board {
  tidStr: string;
  type: number;
  checked: boolean;
  description: string;
  parentFidStr: string;
}

export interface BoardCategory {
  categoryName: string;
  isBookmarkCategory: boolean;
  boardList: Board[];
  subCategoryList: BoardCategory[];
}
