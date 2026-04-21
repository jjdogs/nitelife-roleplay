import { JobsType } from "../types/types";

export const ApiJobs: JobsType[] = [
  {
    name: "lspd",
    label: "LSPD Central",
    gradeLabel: "Sergeant",
    onDuty: true,
    restricted: false,
    active: true,
  },
  {
    name: "ems",
    label: "LS Medical Center",
    gradeLabel: "Paramedic",
    onDuty: false,
    restricted: false,
  },
  {
    name: "mechanic",
    label: "LS Customs",
    gradeLabel: "Lead Tuner",
    onDuty: false,
    restricted: false,
  },
  {
    name: "realestate",
    label: "Dynasty 8",
    gradeLabel: "Senior Agent",
    onDuty: false,
    restricted: false,
  },
  {
    name: "taxi",
    label: "Downtown Cab Co.",
    gradeLabel: "Experienced Driver",
    onDuty: false,
    restricted: false,
  },
  {
    name: "trucker",
    label: "PostOp",
    gradeLabel: "Contract Driver",
    onDuty: false,
    restricted: false,
  },
  {
    name: "mafia",
    label: "The Union",
    gradeLabel: "Associate",
    onDuty: false,
    restricted: true, //
  },
  {
    name: "judge",
    label: "Superior Court",
    gradeLabel: "District Judge",
    onDuty: false,
    restricted: true,
  },
  {
    name: "burger",
    label: "Burgershot",
    gradeLabel: "Kitchen Staff",
    onDuty: false,
    restricted: false,
  },
  {
    name: "news",
    label: "Weazel News",
    gradeLabel: "Field Reporter",
    onDuty: false,
    restricted: false,
  },
];
