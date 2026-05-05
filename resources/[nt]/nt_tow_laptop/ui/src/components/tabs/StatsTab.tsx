import { ScrollArea } from "@mantine/core";
import { TowStats } from "../../types/types";
import { RepBar } from "../shared/RepBar";
import s from "../appStyle.module.css";

interface Props {
  stats: TowStats;
}

export function StatsTab({ stats }: Props) {
  return (
    <ScrollArea h="100%">
      <div className={s.statsContent}>
        <div className={s.statsGrid}>
          <div className={s.statCard}>
            <div className={s.detailLabel}>JOBS DONE</div>
            <div style={{ fontSize: 28, fontWeight: 700, color: "#f0fdf4", marginTop: 6 }}>
              {stats.jobsCompleted}
            </div>
          </div>
          <div className={s.statCard}>
            <div className={s.detailLabel}>STREAK</div>
            <div style={{ fontSize: 28, fontWeight: 700, color: "#f59e0b", marginTop: 6 }}>
              {stats.streak}
            </div>
            <div style={{ fontSize: 9, color: "#6b7280", marginTop: 2 }}>consecutive</div>
          </div>
          <div className={s.statCard}>
            <div className={s.detailLabel}>TOTAL EARNED</div>
            <div style={{ fontSize: 28, fontWeight: 700, color: "#22c55e", marginTop: 6 }}>
              ${stats.totalEarnings.toLocaleString()}
            </div>
          </div>
          <div className={s.statCard}>
            <div className={s.detailLabel}>AVG PAY</div>
            <div style={{ fontSize: 28, fontWeight: 700, color: "#22c55e", marginTop: 6 }}>
              ${stats.avgPay}
            </div>
            <div style={{ fontSize: 9, color: "#6b7280", marginTop: 2 }}>per job</div>
          </div>
        </div>
        <RepBar mode="segments" stats={stats} />
      </div>
    </ScrollArea>
  );
}
