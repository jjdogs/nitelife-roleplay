import { ScrollArea } from "@mantine/core";
import { HistoryEntry } from "../../types/types";
import { HistoryCard } from "../shared/HistoryCard";
import s from "../appStyle.module.css";

interface Props {
  history: HistoryEntry[];
}

export function HistoryTab({ history }: Props) {
  const special = history.filter((h) => h.special);
  const regular = history.filter((h) => !h.special);

  return (
    <ScrollArea h="100%">
      <div className={s.historyList}>
        {special.map((h) => (
          <HistoryCard key={h.id} entry={h} />
        ))}
        {regular.map((h) => (
          <HistoryCard key={h.id} entry={h} />
        ))}
      </div>
    </ScrollArea>
  );
}
