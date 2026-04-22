export interface ReputationEntry {
  name: string;
  value: string;
  desc: string;
  reputation?: number;
  topicSubject?: string;
  postContent?: string;
  author?: string;
  time?: number;
}

export interface AdminForum {
  fid: string;
  name: string;
}

export interface UserProfile {
  uid: string;
  userName: string;
  avatarUrl: string;
  group: string;
  title: string;
  honor: string;
  yz: number;
  money: number;
  fame: number;
  rvrc: number;
  posts: number;
  regdate: number;
  sign: string;
  ipLoc: string;
  medal: string;
  muteTime: string;
  followByNum: number;
  adminForums: AdminForum[] | string;
  reputationEntryList: ReputationEntry[];
}
