import { Tab } from "../types/types";
import classes from "./app.module.css";

interface Properties {
  activeTab: Tab;
  jobCount: number;
  completedCount: number;
}

export const Topbar = ({ activeTab, jobCount, completedCount }: Properties) => {
  const meta: Record<Tab, string> = {
    jobs: `NAVEED CARR · ONLINE · ${jobCount.toString().padStart(2, "0")} JOBS AVAILABLE`,
    history: `JOB HISTORY · ${completedCount} COMPLETED`,
    stats: "PERFORMANCE STATS",
  };

  return (
    <div className={classes.topbar}>
      <div className={classes.topbarLeft}>
        <div className={classes.topbarDot} />
        <span className={classes.topbarTitle}>DISPATCH TERMINAL</span>
      </div>
      <span className={classes.topbarMeta}>{meta[activeTab]}</span>
    </div>
  );
};
