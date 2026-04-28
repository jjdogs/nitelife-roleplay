import {
  Modal,
  ScrollAreaAutosize,
  Checkbox,
  Button,
  Select,
  Stack,
  TextInput,
  NumberInput,
} from "@mantine/core";
import { SelectType } from "../../../types/types";
import { useState } from "react";
import { WhitelistItems } from "./Whitelist/api";
import { TypesInterface } from "./Types/api";
import { CombinedItem } from "./types";
import global from "../../../global.module.css";
import { MultiSelector } from "../MultiSelector";

interface Properties {
  allItems: { value: string; label: string }[];
  allJobs: SelectType[];
  itemTypes: SelectType[];
  item?: CombinedItem | null;
  close: () => void;
  handleSave: (item: CombinedItem) => void;
  type: string;
}

const apiWhitelisted = {
  label: "",
  jobs: [],
  type: [],
  value: "",
  override: false,
};

const apiType = {
  value: "",
  label: "",
  jobs: [],
  event: "av_business:consumable",
  weight: 1000,
};

export const Panel = ({
  allJobs,
  item,
  close,
  itemTypes,
  handleSave,
  allItems,
  type,
}: Properties) => {
  const [tempItem, setTempItem] = useState<WhitelistItems | TypesInterface>(
    item ?? (type == "whitelist" ? apiWhitelisted : apiType),
  );

  const updateField = (field: keyof CombinedItem, value: any) => {
    setTempItem((prev) => ({
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
      title={type == "whitelist" ? "Item Whitelist" : "Item Types"}
    >
      <ScrollAreaAutosize
        h={380}
        type="hover"
        scrollbars="y"
        scrollbarSize={5}
        mx="auto"
      >
        <Stack gap="xs">
          {type === "whitelist" ? (
            <Select
              classNames={global}
              size="xs"
              value={tempItem?.value}
              label="Item name"
              placeholder="Start typing the name..."
              limit={50}
              allowDeselect={false}
              onChange={(e) => {
                if (!e) return;
                const label = allItems.find((item) => item.value === e)?.label;
                updateField("value", e);
                updateField("label", label || e);
              }}
              searchable
              data={allItems}
            />
          ) : (
            <>
              <TextInput
                classNames={global}
                size="xs"
                value={tempItem?.value}
                description="An unique value. Used for the script to identify the type."
                label="Type name"
                onChange={(e) => {
                  updateField("value", e.currentTarget.value.toLowerCase());
                }}
              />
              <TextInput
                classNames={global}
                size="xs"
                value={tempItem?.label}
                description="This is how Businesses will see it in their APP"
                label="Type label"
                onChange={(e) => {
                  updateField("label", e.currentTarget.value);
                }}
              />
            </>
          )}
          <MultiSelector
            label="Allowed Jobs"
            description={
              type == "whitelist"
                ? "Select the jobs with access to this item."
                : "Limit access to specific jobs. If none are selected, this item type will be available to everyone."
            }
            values={tempItem?.jobs ? tempItem.jobs : undefined}
            data={allJobs}
            updateData={(e) => {
              updateField("jobs", e);
            }}
          />
          {type === "whitelist" ? (
            <>
              <MultiSelector
                label="Item Types"
                description="Select the categories this item belongs to."
                values={(tempItem as WhitelistItems).type}
                data={itemTypes}
                updateData={(e) => {
                  updateField("type", e);
                }}
              />
              <Checkbox
                classNames={global}
                mt="xs"
                size="xs"
                label="Override Item"
                description="Leave it unchecked if the item is already registered in a different script."
                checked={(tempItem as WhitelistItems).override}
                onChange={(e) => {
                  updateField("override", e.currentTarget.checked);
                }}
              />
            </>
          ) : (
            <>
              <NumberInput
                classNames={global}
                label="Item Weight"
                description="Default weight for this item types"
                size="xs"
                min={0}
                max={1000000}
                value={(tempItem as CombinedItem).weight}
                onChange={(e) => {
                  updateField("weight", Number(e));
                }}
              />
              <TextInput
                classNames={global}
                size="xs"
                label="Client Event"
                description="Client event triggered on consumption. Leave empty to disable all effects and events."
                value={(tempItem as CombinedItem).event}
                placeholder="e.g., av_business:consumable"
                onChange={(e) => updateField("event", e.currentTarget.value)}
              />
              <Checkbox
                classNames={global}
                size="xs"
                mt="xs"
                mb="xs"
                checked={(tempItem as CombinedItem).remove}
                label="Remove on use"
                description="If checked, the item will be removed on use."
                onChange={(e) => updateField("remove", e.currentTarget.checked)}
              />
            </>
          )}
        </Stack>
      </ScrollAreaAutosize>
      <Button
        className={global.button}
        variant="filled"
        size="xs"
        mt="md"
        fullWidth
        disabled={tempItem.value.length == 0 || tempItem.label.length == 0}
        onClick={() => {
          handleSave(tempItem as CombinedItem);
        }}
      >
        Save
      </Button>
    </Modal>
  );
};
