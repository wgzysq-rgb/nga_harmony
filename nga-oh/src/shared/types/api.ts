export interface ApiResponse<T = any> {
  ok: boolean;
  data?: T;
  error?: string;
}
