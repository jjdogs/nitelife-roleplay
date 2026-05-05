# av_laptop App Development Conventions

Derived from `av_contacts` — the reference resource for all laptop ecosystem apps.

---

## Folder structure

```
src/
├── API/                        ← uppercase folder, mock/api data only
│   └── entityName.ts           ← camelCase filename
├── components/
│   ├── app.module.css          ← app-level styles (not appStyle.module.css)
│   ├── MainApp.tsx             ← shell only, ~25-30 lines
│   ├── Loading.tsx             ← shared utils at components/ root
│   ├── SharedComponent.tsx     ← shared components at root, NOT in shared/
│   ├── FeatureName/            ← PascalCase feature folder
│   │   ├── FeatureName.tsx     ← same name as folder (the tab/view component)
│   │   └── SubComponent.tsx    ← sub-components live in same folder
│   └── AnotherFeature/
│       ├── AnotherFeature.tsx
│       └── SubComponent.tsx
├── hooks/
│   └── useNuiEvents.ts
├── reducers/
│   └── atoms.ts
└── types/
    └── types.ts
```

---

## Naming rules

| Thing | Convention | Example |
|-------|-----------|---------|
| Feature folders | PascalCase | `Jobs/`, `History/`, `Stats/` |
| Feature main file | Matches folder name | `Jobs/Jobs.tsx` |
| Sub-components | PascalCase in same folder | `Jobs/JobCard.tsx` |
| Shared components | PascalCase at `components/` root | `RepBar.tsx` |
| App CSS module | Always `app.module.css` | — |
| API mock file | camelCase | `API/tow.ts` |
| CSS module import var | `classes` | `import classes from "./app.module.css"` |

### Do NOT use:
- `tabs/` folder
- `shared/` folder
- `appStyle.module.css`
- `import s from ...` — always use `classes`

---

## Component conventions

**Props interface** — always `Properties`:
```tsx
interface Properties {
  items: ItemType[];
  onSelect: (id: string) => void;
}
```

**Export style** — named const arrow function:
```tsx
export const Jobs = ({ jobs, selectedJobId, onSelectJob }: Properties) => {
  return ( ... );
};
```

**Internal-only sub-components** (not exported) live in the same file as their parent:
```tsx
// DetailPanel is only used by Jobs — stays in Jobs.tsx
const DetailPanel = ({ job }: { job: TowJob | null }) => { ... };

export const Jobs = ({ ... }: Properties) => {
  return ( ... <DetailPanel job={selectedJob} /> ... );
};
```

---

## API layer (`API/`)

Mock data lives in `API/`, named with `Api` prefix + PascalCase entity:
```ts
// API/tow.ts
import { TowJob, HistoryEntry, TowStats } from "../types/types";

export const ApiJobs: TowJob[] = [...];
export const ApiHistory: HistoryEntry[] = [...];
export const ApiStats: TowStats = { ... };
```

When real NUI events are wired in, this file is where the fallback mock data lives (checked via `isEnvBrowser()`).

---

## Types (`types/types.ts`)

Use `type` keyword, `Type` suffix for data shape types:
```ts
export type ContactsType = {
  identifier: string;
  name: string;
};
```

Tab/union types don't need the suffix:
```ts
export type Tab = "jobs" | "history" | "stats";
export type JobType = "tow" | "fix" | "contract" | "locked";
```

---

## CSS module usage

One `app.module.css` at `components/` root covers all styles.  
Import with `classes`, not `s`:
```tsx
import classes from "../app.module.css";  // depth-2 component
import classes from "./app.module.css";   // depth-1 component

// Single class
<div className={classes.container}>

// Conditional/combined classes
<div className={`${classes.badge} ${classes.badgeTow}`}>
<div className={`${classes.navBtn}${active ? ` ${classes.navBtnActive}` : ""}`}>
```

---

## MainApp.tsx pattern

`MainApp.tsx` is the layout shell only — it holds tab state and wires together the top-level components. No rendering logic belongs here.

```tsx
import { useState } from "react";
import { Tab } from "../types/types";
import { ApiJobs, ApiHistory, ApiStats } from "../API/tow";
import { Sidebar } from "./Sidebar";
import { Topbar } from "./Topbar";
import { Jobs } from "./Jobs/Jobs";
import { History } from "./History/History";
import { Stats } from "./Stats/Stats";
import classes from "./app.module.css";

export const MainApp = () => {
  const [activeTab, setActiveTab] = useState<Tab>("jobs");
  const [selectedJobId, setSelectedJobId] = useState("j1");

  return (
    <div className={classes.container}>
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />
      <div className={classes.main}>
        <Topbar activeTab={activeTab} jobCount={...} completedCount={...} />
        <div className={classes.content}>
          {activeTab === "jobs" && <Jobs jobs={ApiJobs} ... />}
          {activeTab === "history" && <History history={ApiHistory} />}
          {activeTab === "stats" && <Stats stats={ApiStats} />}
        </div>
      </div>
    </div>
  );
};
```
