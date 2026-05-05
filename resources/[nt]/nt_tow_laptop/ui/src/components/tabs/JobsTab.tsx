import { ScrollArea } from "@mantine/core";
import { TowJob } from "../../types/types";
import { JobCard } from "../shared/JobCard";
import { RepBar } from "../shared/RepBar";
import s from "../appStyle.module.css";

// DetailPanel is internal to this tab — not reused anywhere else
function DetailPanel({ job }: { job: TowJob | null }) {
  if (!job) {
    return (
      <div className={s.detailPanel}>
        <div className={s.detailEmpty}>SELECT A JOB</div>
      </div>
    );
  }

  return (
    <div className={s.detailPanel}>
      {/* Row 1: Owner | Vehicle */}
      <div className={s.detailRow}>
        <div className={s.detailField}>
          <div className={s.detailLabel}>OWNER</div>
          <div className={s.detailValue} style={{ color: "#f0fdf4" }}>
            {job.ownerName}
          </div>
        </div>
        <div className={s.detailField}>
          <div className={s.detailLabel}>VEHICLE</div>
          <div className={s.detailValue} style={{ color: "#f0fdf4" }}>
            {job.vehicleModel}
          </div>
        </div>
      </div>

      {/* Row 2: Reason */}
      <div className={s.detailRow}>
        <div className={s.detailField}>
          <div className={s.detailLabel}>REASON</div>
          <div className={s.detailValue} style={{ color: "#6b7280" }}>
            {job.reason}
          </div>
        </div>
      </div>

      {/* Row 3: Type | Distance | Payout */}
      <div className={s.detailRow}>
        <div className={s.detailField}>
          <div className={s.detailLabel}>TYPE</div>
          <div className={s.detailValue} style={{ color: "#22c55e" }}>
            {job.jobType.toUpperCase()}
          </div>
        </div>
        <div className={s.detailField}>
          <div className={s.detailLabel}>DISTANCE</div>
          <div className={s.detailValue} style={{ color: "#6b7280" }}>
            {job.distance}
          </div>
        </div>
        <div className={s.detailField}>
          <div className={s.detailLabel}>PAYOUT</div>
          <div className={s.detailValue} style={{ color: "#22c55e" }}>
            ${job.payAmount}
          </div>
        </div>
      </div>

      {/* Row 4: Rep bar */}
      <RepBar mode="line" tier="Reliable" points={42} />

      {/* Tip */}
      {job.tip && <div className={s.tipLine}>{job.tip}</div>}

      {/* Actions */}
      <div className={s.actionRow}>
        <button className={s.btnAccept}>ACCEPT</button>
        <button className={s.btnDeny}>DENY</button>
      </div>
    </div>
  );
}

interface Props {
  jobs: TowJob[];
  selectedJobId: string;
  onSelectJob: (id: string) => void;
}

export function JobsTab({ jobs, selectedJobId, onSelectJob }: Props) {
  const regularJobs = jobs.filter((j) => !j.special && !j.locked);
  const specialJobs = jobs.filter((j) => j.special || j.locked);
  const selectedJob = jobs.find((j) => j.id === selectedJobId) ?? null;

  return (
    <div className={s.jobsLayout}>
      <div className={s.jobList}>
        <ScrollArea h="100%">
          <div className={s.sectionLabel}>ACTIVE JOBS</div>
          {regularJobs.map((job) => (
            <JobCard
              key={job.id}
              job={job}
              selected={selectedJobId === job.id}
              onClick={() => onSelectJob(job.id)}
            />
          ))}
          <div className={s.sectionLabel} style={{ marginTop: 4 }}>
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
        </ScrollArea>
      </div>
      <DetailPanel job={selectedJob} />
    </div>
  );
}
