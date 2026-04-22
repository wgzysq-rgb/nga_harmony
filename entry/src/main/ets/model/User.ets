export interface User {
  userId: string;
  nickName: string;
  cid: string;
  avatarUrl: string;
}

export class ProfileData {
  uid: string = '';
  userName: string = '';
  avatarUrl: string = '';
  group: string = '';
  title: string = '';
  honor: string = '';
  yz: number = 0;
  money: string = '';
  fame: string = '';
  rvrc: string = '';
  posts: string = '';
  regdate: string = '';
  sign: string = '';
  ipLoc: string = '';
  medal: string = '';
  muteTime: string = '';
  followByNum: string = '';
  adminForums: AdminForumsData[] = [];
  reputationEntryList: ReputationData[] = [];
}

export class AdminForumsData {
  fid: string = '';
  forumName: string = '';
}

export class ReputationData {
  name: string = '';
  value: string = '';
  desc: string = '';
  reputation: number = 0;
  topicSubject: string = '';
  postContent: string = '';
  author: string = '';
  time: number = 0;
}
