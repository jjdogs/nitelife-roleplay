import { Tab } from "../types/types";
import classes from "./app.module.css";

interface Properties {
  activeTab: Tab;
  onTabChange: (tab: Tab) => void;
}

export const Sidebar = ({ activeTab, onTabChange }: Properties) => {
  return (
    <div className={classes.sidebar}>
      <div className={classes.logo}>NT·TOW</div>
      <button
        className={`${classes.navBtn}${activeTab === "jobs" ? ` ${classes.navBtnActive}` : ""}`}
        onClick={() => onTabChange("jobs")}
        title="Active Jobs"
      >
        <i className="fa-solid fa-truck-moving" />
      </button>
      <button
        className={`${classes.navBtn}${activeTab === "history" ? ` ${classes.navBtnActive}` : ""}`}
        onClick={() => onTabChange("history")}
        title="History"
      >
        <i className="fa-solid fa-clock-rotate-left" />
      </button>
      <button
        className={`${classes.navBtn}${activeTab === "stats" ? ` ${classes.navBtnActive}` : ""}`}
        onClick={() => onTabChange("stats")}
        title="Stats"
      >
        <i className="fa-solid fa-chart-simple" />
      </button>
    </div>
  );
};
