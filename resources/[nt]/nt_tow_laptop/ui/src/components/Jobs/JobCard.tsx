import { TowJob, JobType } from "../../types/types";
import classes from "../app.module.css";

const TYPE_CLASS: Record<JobType, string> = {
  tow: classes.badgeTow,
  fix: classes.badgeFix,
  contract: classes.badgeContract,
  locked: classes.badgeLocked,
};

const TYPE_LABEL: Record<JobType, string> = {
  tow: "TOW",
  fix: "FIX",
  contract: "CONTRACT",
  locked: "LOCKED",
};

interface Properties {
  job: TowJob;
  selected: boolean;
  onClick: () => void;
}

export const JobCard = ({ job, selected, onClick }: Properties) => {
  const cardClasses = [classes.jobCard];
  if (job.locked) {
    cardClasses.push(classes.jobCardLocked);
  } else if (job.special) {
    cardClasses.push(selected ? classes.jobCardSpecialSelected : classes.jobCardSpecial);
  } else if (selected) {
    cardClasses.push(classes.jobCardSelected);
  }

  return (
    <div className={cardClasses.join(" ")} onClick={job.locked ? undefined : onClick}>
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
          <span className={`${classes.badge} ${classes.badgeLocked}`}>???</span>
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
      <span className={`${classes.badge} ${TYPE_CLASS[job.jobType]}`}>
        {TYPE_LABEL[job.jobType]}
      </span>
    </div>
  );
};
