import { useEffect, useState } from "react";
import { Tab, TowJob, TowStats } from "../types/types";
import { useNuiEvent, fetchNui, isEnvBrowser } from "../hooks/useNuiEvents";
import { JOBS, HISTORY, STATS } from "../data/mockData";
import { Sidebar } from "./Sidebar";
import { Topbar } from "./Topbar";
import { Jobs } from "./Jobs/Jobs";
import { History } from "./History/History";
import { Stats } from "./Stats/Stats";
import classes from "./app.module.css";

const RESOURCE = "nt_tow_laptop";

const emptyStats: TowStats = {
  jobsCompleted: 0,
  streak: 0,
  totalEarnings: 0,
  avgPay: 0,
  repPoints: 0,
  repTier: "New",
};

export const MainApp = () => {
  const [activeTab, setActiveTab] = useState<Tab>("jobs");
  const [selectedJobId, setSelectedJobId] = useState<string | null>(null);
  const [jobs, setJobs] = useState<TowJob[]>(isEnvBrowser() ? JOBS : []);
  const [hasActiveJob, setHasActiveJob] = useState(false);

  useEffect(() => {
    fetchNui(RESOURCE, "tow:open");
  }, []);

  useNuiEvent<TowJob[]>("tow:setJobs", (data) => {
    setJobs(data);
    setHasActiveJob(false);
    setSelectedJobId(data.length > 0 ? data[0].id : null);
  });

  useNuiEvent("tow:jobActive", () => {
    setJobs([]);
    setHasActiveJob(true);
  });

  useNuiEvent("tow:jobComplete", () => {
    setJobs([]);
    setHasActiveJob(false);
  });

  const handleAccept = (jobId: string) => {
    fetchNui(RESOURCE, "tow:acceptJob", { jobId });
  };

  const handleDeny = (jobId: string) => {
    const remaining = jobs.filter((j) => j.id !== jobId);
    setJobs(remaining);
    if (selectedJobId === jobId) {
      setSelectedJobId(remaining.length > 0 ? remaining[0].id : null);
    }
  };

  const stats: TowStats = isEnvBrowser() ? STATS : emptyStats;
  const history = isEnvBrowser() ? HISTORY : [];
  const availableCount = jobs.filter((j) => !j.locked).length;

  return (
    <div className={classes.container}>
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />
      <div className={classes.main}>
        <Topbar
          activeTab={activeTab}
          jobCount={availableCount}
          completedCount={stats.jobsCompleted}
        />
        <div className={classes.content}>
          {activeTab === "jobs" && (
            <Jobs
              jobs={jobs}
              selectedJobId={selectedJobId}
              onSelectJob={setSelectedJobId}
              onAccept={handleAccept}
              onDeny={handleDeny}
              hasActiveJob={hasActiveJob}
            />
          )}
          {activeTab === "history" && <History history={history} />}
          {activeTab === "stats" && <Stats stats={stats} />}
        </div>
      </div>
    </div>
  );
};
