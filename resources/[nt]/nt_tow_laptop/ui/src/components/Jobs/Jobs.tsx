import { ScrollArea } from "@mantine/core";
import { TowJob } from "../../types/types";
import { JobCard } from "./JobCard";
import { RepBar } from "../RepBar";
import classes from "../app.module.css";

interface Properties {
  jobs: TowJob[];
  selectedJobId: string | null;
  onSelectJob: (id: string) => void;
  onAccept: (id: string) => void;
  onDeny: (id: string) => void;
  hasActiveJob: boolean;
}

const DetailPanel = ({
  job,
  onAccept,
  onDeny,
}: {
  job: TowJob | null;
  onAccept: (id: string) => void;
  onDeny: (id: string) => void;
}) => {
  if (!job) {
    return (
      <div className={classes.detailPanel}>
        <div className={classes.detailEmpty}>SELECT A JOB</div>
      </div>
    );
  }

  return (
    <div className={classes.detailPanel}>
      <div className={classes.detailRow}>
        <div className={classes.detailField}>
          <div className={classes.detailLabel}>OWNER</div>
          <div className={classes.detailValue} style={{ color: "#f0fdf4" }}>
            {job.ownerName}
          </div>
        </div>
        <div className={classes.detailField}>
          <div className={classes.detailLabel}>VEHICLE</div>
          <div className={classes.detailValue} style={{ color: "#f0fdf4" }}>
            {job.vehicleModel}
          </div>
        </div>
      </div>

      <div className={classes.detailRow}>
        <div className={classes.detailField}>
          <div className={classes.detailLabel}>REASON</div>
          <div className={classes.detailValue} style={{ color: "#6b7280" }}>
            {job.reason}
          </div>
        </div>
      </div>

      <div className={classes.detailRow}>
        <div className={classes.detailField}>
          <div className={classes.detailLabel}>TYPE</div>
          <div className={classes.detailValue} style={{ color: "#22c55e" }}>
            {job.jobType.toUpperCase()}
          </div>
        </div>
        {job.distance && (
          <div className={classes.detailField}>
            <div className={classes.detailLabel}>DISTANCE</div>
            <div className={classes.detailValue} style={{ color: "#6b7280" }}>
              {job.distance}
            </div>
          </div>
        )}
        <div className={classes.detailField}>
          <div className={classes.detailLabel}>PAYOUT</div>
          <div className={classes.detailValue} style={{ color: "#22c55e" }}>
            ${job.payAmount}
          </div>
        </div>
      </div>

      <RepBar mode="line" tier="Reliable" points={42} />

      {job.tip && <div className={classes.tipLine}>{job.tip}</div>}

      <div className={classes.actionRow}>
        <button className={classes.btnAccept} onClick={() => onAccept(job.id)}>
          ACCEPT
        </button>
        <button className={classes.btnDeny} onClick={() => onDeny(job.id)}>
          DENY
        </button>
      </div>
    </div>
  );
};

const EmptyState = ({ hasActiveJob }: { hasActiveJob: boolean }) => (
  <div className={classes.detailPanel}>
    <div className={classes.detailEmpty}>
      {hasActiveJob ? "JOB IN PROGRESS" : "NO JOBS AVAILABLE"}
    </div>
  </div>
);

export const Jobs = ({
  jobs,
  selectedJobId,
  onSelectJob,
  onAccept,
  onDeny,
  hasActiveJob,
}: Properties) => {
  const regularJobs = jobs.filter((j) => !j.special && !j.locked);
  const specialJobs = jobs.filter((j) => j.special || j.locked);
  const selectedJob = jobs.find((j) => j.id === selectedJobId) ?? null;

  if (jobs.length === 0) {
    return (
      <div className={classes.jobsLayout}>
        <EmptyState hasActiveJob={hasActiveJob} />
      </div>
    );
  }

  return (
    <div className={classes.jobsLayout}>
      <div className={classes.jobList}>
        <ScrollArea h="100%">
          <div className={classes.sectionLabel}>ACTIVE JOBS</div>
          {regularJobs.map((job) => (
            <JobCard
              key={job.id}
              job={job}
              selected={selectedJobId === job.id}
              onClick={() => onSelectJob(job.id)}
            />
          ))}
          {specialJobs.length > 0 && (
            <>
              <div className={classes.sectionLabel} style={{ marginTop: 4 }}>
                SPECIAL
              </div>
              {specialJobs.map((job) => (
                <JobCard
                  key={job.id}
                  job={job}
                  selected={selectedJobId === job.id}
                  onClick={() => onSelectJob(job.id)}
                />
              ))}
            </>
          )}
        </ScrollArea>
      </div>
      <DetailPanel job={selectedJob} onAccept={onAccept} onDeny={onDeny} />
    </div>
  );
};
