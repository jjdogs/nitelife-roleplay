import { TowJob, JobType } from "../../types/types";
import s from "../appStyle.module.css";

const TYPE_CLASS: Record<JobType, string> = {
  tow: s.badgeTow,
  fix: s.badgeFix,
  contract: s.badgeContract,
  locked: s.badgeLocked,
};

const TYPE_LABEL: Record<JobType, string> = {
  tow: "TOW",
  fix: "FIX",
  contract: "CONTRACT",
  locked: "LOCKED",
};

interface Props {
  job: TowJob;
  selected: boolean;
  onClick: () => void;
}

export function JobCard({ job, selected, onClick }: Props) {
  const classes = [s.jobCard];
  if (job.locked) {
    classes.push(s.jobCardLocked);
  } else if (job.special) {
    classes.push(selected ? s.jobCardSpecialSelected : s.jobCardSpecial);
  } else if (selected) {
    classes.push(s.jobCardSelected);
  }

  return (
    <div className={classes.join(" ")} onClick={job.locked ? undefined : onClick}>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 4,
        }}
      >
        <span
          style={{
            fontSize: 12,
            fontWeight: 700,
            color: job.locked ? "#374151" : job.special ? "#a855f7" : "#22c55e",
          }}
        >
          {job.vehicleModel}
        </span>
        {job.locked ? (
          <span className={`${s.badge} ${s.badgeLocked}`}>???</span>
        ) : (
          <span
            style={{
              fontSize: 12,
              fontWeight: 700,
              color: job.special ? "#a855f7" : "#22c55e",
            }}
          >
            ${job.payAmount}
          </span>
        )}
      </div>
      <div style={{ fontSize: 10, color: "#6b7280", marginBottom: 7, lineHeight: 1.4 }}>
        {job.reason}
      </div>
      <span className={`${s.badge} ${TYPE_CLASS[job.jobType]}`}>
        {TYPE_LABEL[job.jobType]}
      </span>
    </div>
  );
}
