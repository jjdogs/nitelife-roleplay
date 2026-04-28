import { Employee } from "../../../types/types";

export const sortEmployeesAlphabetically = (employees: Employee[]) => {
  return [...employees].sort((a, b) => {
    const nameA = a.name || "";
    const nameB = b.name || "";
    return nameA.localeCompare(nameB, "es", { sensitivity: "base" });
  });
};
