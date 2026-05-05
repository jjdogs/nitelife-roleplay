import { HistoryEntry, JobStatus } from "../../types/types";
import classes from "../app.module.css";

const STATUS_CLASS: Record<JobStatus, string> = {
  done: classes.badgeDone,
  failed: classes.badgeFailed,
  contract: classes.badgeContract,
};

const STATUS_LABEL: Record<JobStatus, string> = {
  done: "DONE",
  failed: "FAILED",
  contract: "CONTRACT",
};

interface Properties {
  entry: HistoryEntry;
}

export const HistoryCard = ({ entry }: Properties) => {
  const isFailed = entry.status === "failed";
  const isContract = entry.status === "contract";

  return (
    <div className={`${classes.historyCard}${entry.special ? ` ${classes.historyCardSpecial}` : ""}`}>
      <div style={{ minWidth: 0 }}>
        <div
          style={{
            fontSize: 12,
            fontWeight: 700,
            color: entry.special ? "#a855f7" : "#f0fdf4",
            marginBottom: 4,
            display: "flex",
            alignItems: "center",
            gap: 6,
          }}
        >
          {entry.special && (
            <i className="fa-solid fa-star" style={{ fontSize: 9, color: "#7c3aed" }} />
          )}
          {entry.ownerName}
        </div>
        <div style={{ fontSize: 10, color: "#6b7280", marginBottom: 3 }}>
          {entry.vehicleModel} · {entry.location}
        </div>
        <div style={{ fontSize: 9, color: "#374151" }}>{entry.timeAgo}</div>
        {entry.repeatLine && (
          <div style={{ fontSize: 9, color: "#f59e0b", marginTop: 5 }}>
            // {entry.repeatLine}
          </div>
        )}
      </div>
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "flex-end",
          gap: 6,
          flexShrink: 0,
        }}
      >
        <span className={`${classes.badge} ${STATUS_CLASS[entry.status]}`}>
          {STATUS_LABEL[entry.status]}
        </span>
        <span
          style={{
            fontSize: 13,
            fontWeight: 700,
            color: isFailed ? "#ef4444" : isContract ? "#a855f7" : "#22c55e",
          }}
        >
          ${entry.payAmount}
        </span>
      </div>
    </div>
  );
};
