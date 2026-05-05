import { TowStats } from "../types/types";
import classes from "./app.module.css";

const TIERS = ["NEW BLOOD", "RELIABLE", "TRUSTED", "SENIOR"];

interface LineProperties {
  mode: "line";
  tier: string;
  points: number;
}

interface SegmentsProperties {
  mode: "segments";
  stats: TowStats;
}

type RepBarProperties = LineProperties | SegmentsProperties;

export const RepBar = (props: RepBarProperties) => {
  if (props.mode === "line") {
    return (
      <div className={classes.repField}>
        <div
          style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}
        >
          <div className={classes.detailLabel}>NAVEED REP</div>
          <div style={{ fontSize: 10, fontWeight: 700, color: "#22c55e" }}>
            {props.tier.toUpperCase()} · {props.points}
          </div>
        </div>
        <div className={classes.repBar}>
          <div className={classes.repBarFill} style={{ width: `${props.points}%` }} />
        </div>
      </div>
    );
  }

  const { stats } = props;
  const filledSegs = Math.round(stats.repPoints / 10);
  const activeTier = stats.repTier.toUpperCase();

  return (
    <div className={classes.repSection}>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 2,
        }}
      >
        <div className={classes.detailLabel}>NAVEED REPUTATION</div>
        <div style={{ fontSize: 10, fontWeight: 700, color: "#22c55e" }}>
          {stats.repTier.toUpperCase()} · {stats.repPoints}
        </div>
      </div>
      <div className={classes.segBar}>
        {Array.from({ length: 10 }, (_, i) => (
          <div
            key={i}
            className={classes.seg}
            style={{ background: i < filledSegs ? "#22c55e" : "#1a2a1a" }}
          />
        ))}
      </div>
      <div className={classes.tierLabels}>
        {TIERS.map((tier) => (
          <span
            key={tier}
            className={`${classes.tierLabel}${tier === activeTier ? ` ${classes.tierLabelActive}` : ""}`}
          >
            {tier}
          </span>
        ))}
      </div>
    </div>
  );
};
