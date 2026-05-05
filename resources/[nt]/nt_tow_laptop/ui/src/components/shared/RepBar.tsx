import { TowStats } from "../../types/types";
import s from "../appStyle.module.css";

const TIERS = ["NEW BLOOD", "RELIABLE", "TRUSTED", "SENIOR"];

interface LineProps {
  mode: "line";
  tier: string;
  points: number;
}

interface SegmentsProps {
  mode: "segments";
  stats: TowStats;
}

type RepBarProps = LineProps | SegmentsProps;

export function RepBar(props: RepBarProps) {
  if (props.mode === "line") {
    return (
      <div className={s.repField}>
        <div
          style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}
        >
          <div className={s.detailLabel}>NAVEED REP</div>
          <div style={{ fontSize: 10, fontWeight: 700, color: "#22c55e" }}>
            {props.tier.toUpperCase()} · {props.points}
          </div>
        </div>
        <div className={s.repBar}>
          <div className={s.repBarFill} style={{ width: `${props.points}%` }} />
        </div>
      </div>
    );
  }

  const { stats } = props;
  const filledSegs = Math.round(stats.repPoints / 10);
  const activeTier = stats.repTier.toUpperCase();

  return (
    <div className={s.repSection}>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 2,
        }}
      >
        <div className={s.detailLabel}>NAVEED REPUTATION</div>
        <div style={{ fontSize: 10, fontWeight: 700, color: "#22c55e" }}>
          {stats.repTier.toUpperCase()} · {stats.repPoints}
        </div>
      </div>
      <div className={s.segBar}>
        {Array.from({ length: 10 }, (_, i) => (
          <div
            key={i}
            className={s.seg}
            style={{ background: i < filledSegs ? "#22c55e" : "#1a2a1a" }}
          />
        ))}
      </div>
      <div className={s.tierLabels}>
        {TIERS.map((tier) => (
          <span
            key={tier}
            className={`${s.tierLabel}${tier === activeTier ? ` ${s.tierLabelActive}` : ""}`}
          >
            {tier}
          </span>
        ))}
      </div>
    </div>
  );
}
