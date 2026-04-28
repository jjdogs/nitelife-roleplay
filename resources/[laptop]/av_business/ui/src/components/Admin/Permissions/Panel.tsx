import { useState } from "react";
import {
  Modal,
  MultiSelect,
  Stack,
  TextInput,
  Button,
  Checkbox,
} from "@mantine/core";
import { PermissionsType } from "./api";
import { SelectType } from "../../../types/types";
import global from "../../../global.module.css";
import { MultiSelector } from "../MultiSelector";

export const Panel = ({
  permission,
  allJobs,
  close,
  handleSave,
}: {
  permission: PermissionsType | null;
  allJobs: SelectType[];
  close: () => void;
  handleSave: (permission: PermissionsType) => void;
}) => {
  const [data, setData] = useState(
    permission ?? { value: "", label: "", jobs: [], default: false },
  );
  const updateField = (field: keyof PermissionsType, value: any) => {
    setData((prev) => ({
      ...prev,
      [field]: value,
    }));
  };
  return (
    <Modal
      classNames={global}
      opened
      onClose={close}
      withinPortal={false}
      centered
      lockScroll={false}
      size={355}
      title="Permission"
    >
      <Stack gap="xs">
        <TextInput
          classNames={global}
          size="xs"
          value={data.value}
          label="Permission"
          description="The permission name, used for code and exports"
          onChange={(e) => {
            updateField("value", e.currentTarget.value);
          }}
        />
        <TextInput
          classNames={global}
          size="xs"
          value={data.label}
          label="Label"
          description="This is how players will see it on their APP"
          onChange={(e) => {
            updateField("label", e.currentTarget.value);
          }}
        />
        <MultiSelector
          label="Exclusive Job Access"
          description="Limit access to specific jobs. If none are selected, this permission will be available to everyone."
          data={allJobs}
          values={data.jobs ? data.jobs : undefined}
          updateData={(e) => {
            updateField("jobs", e);
          }}
        />
        <Checkbox
          mt="xs"
          classNames={global}
          size="xs"
          checked={data.default}
          label="Default Permission"
          description="Automatically grant this permission to all newly hired employees."
          onChange={(e) => {
            updateField("default", e.currentTarget.checked);
          }}
        />
        <Button
          className={global.button}
          variant="filled"
          size="xs"
          mt="sm"
          disabled={data.value.length == 0 || data.label.length == 0}
          onClick={() => {
            handleSave(data);
          }}
        >
          Save
        </Button>
      </Stack>
    </Modal>
  );
};
