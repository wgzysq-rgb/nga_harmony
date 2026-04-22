export interface ApiResponse<T = object> {
  ok: boolean;
  data?: T;
  error?: string;
}

export interface SessionInfo {
  uid: string;
  cid: string;
  nickName: string;
  avatarUrl: string;
}

export interface LoginResult {
  success: boolean;
  uid?: string;
  cid?: string;
  rawBody?: string;
  statusCode: number;
  setCookies?: string[];
  error?: string;
}

export interface LoginV2Result extends LoginResult {
  captchaRequired?: boolean;
  captchaId?: string;
}
