import { Group, Button, Select } from "@mantine/core";
import global from "../../../global.module.css";
import { SelectType } from "../../../types/types";
import { fetchNui } from "../../../hooks/useNuiEvents";

interface Properties {
  allJobs: SelectType[];
  job: string | null;
  tab: string;
  setJob: (option: string | null) => void;
  setTab: (option: string) => void;
}

export const Header = ({ allJobs, setJob, job, tab, setTab }: Properties) => {
  const subTabs = [
    { value: "overview", label: "Overview" },
    { value: "zones", label: "Zones" },
    { value: "products", label: "Products" },
  ];
  return (
    <Group>
      <Select
        classNames={global}
        placeholder="Select a job"
        size="xs"
        data={allJobs}
        searchable
        onChange={(e) => {
          setJob(e);
        }}
      />
      <Group ml="auto">
        {job && (
          <Select
            classNames={global}
            value={tab}
            size="xs"
            allowDeselect={false}
            data={subTabs}
            onChange={(e) => {
              if (!e) return;
              setTab(e);
            }}
            disabled={job === null}
          />
        )}

        <Button
          className={global.button}
          size="xs"
          onClick={() => {
            fetchNui("av_business", "newZone", job);
          }}
        >
          Create Job Zone
        </Button>
      </Group>
    </Group>
  );
};
