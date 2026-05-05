import { ScrollArea } from "@mantine/core";
import { HistoryEntry } from "../../types/types";
import { HistoryCard } from "./HistoryCard";
import classes from "../app.module.css";

interface Properties {
  history: HistoryEntry[];
}

export const History = ({ history }: Properties) => {
  const special = history.filter((h) => h.special);
  const regular = history.filter((h) => !h.special);

  return (
    <ScrollArea h="100%">
      <div className={classes.historyList}>
        {special.map((h) => (
          <HistoryCard key={h.id} entry={h} />
        ))}
        {regular.map((h) => (
          <HistoryCard key={h.id} entry={h} />
        ))}
      </div>
    </ScrollArea>
  );
};
