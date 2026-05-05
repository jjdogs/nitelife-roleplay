export type Tab = "jobs" | "history" | "stats";
export type JobType = 'tow' | 'fix' | 'contract' | 'locked';
export type JobStatus = 'done' | 'failed' | 'contract';

export interface TowJob {
  id: string;
  vehicleModel: string;
  plateOrTag?: string;
  ownerName: string;
  reason: string;
  jobType: JobType;
  distance?: string;
  payAmount: number;
  special?: boolean;
  locked?: boolean;
  tip?: string;
}

export interface HistoryEntry {
  id: string;
  ownerName: string;
  vehicleModel: string;
  location: string;
  timeAgo: string;
  status: JobStatus;
  payAmount: number;
  special?: boolean;
  repeatLine?: string;
}

export interface TowStats {
  jobsCompleted: number;
  streak: number;
  totalEarnings: number;
  avgPay: number;
  repPoints: number;
  repTier: string;
}
