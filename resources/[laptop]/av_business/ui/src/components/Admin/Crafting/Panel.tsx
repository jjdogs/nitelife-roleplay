import {
  Modal,
  NumberInput,
  Button,
  ScrollArea,
  Stack,
  Grid,
  TextInput,
  Group,
} from "@mantine/core";
import { useState } from "react";
import { ApiCraftingItem, CraftingAction } from "./api";
import { PropList } from "../Animations/Propslist";
import { AnimType } from "../Animations/api";
import { fetchNui } from "../../../hooks/useNuiEvents";
import global from "../../../global.module.css";

interface Properties {
  item?: CraftingAction | null;
  handleSave: (item: CraftingAction) => void;
  close: () => void;
}

export const Panel = ({ item, handleSave, close }: Properties) => {
  const [tempItem, setTempItem] = useState<CraftingAction>(() => {
    const base = item ?? ApiCraftingItem;
    return {
      ...base,
      anim: base.anim ?? { clip: "", dict: "" },
      prop: base.prop ?? {
        model: "",
        bone: 0,
        pos: { x: 0, y: 0, z: 0 },
        rot: { x: 0, y: 0, z: 0 },
      },
    };
  });

  const updateField = (
    field: keyof CraftingAction | keyof AnimType,
    value: any,
  ) => {
    setTempItem((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  const updateAnim = (field: keyof CraftingAction["anim"], value: string) => {
    setTempItem((prev) => ({
      ...prev,
      anim: { ...prev.anim!, [field]: value },
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
      size="auto"
      title={"Crafting Panel"}
      styles={{
        content: {
          minWidth: 600,
        },
      }}
    >
      <ScrollArea
        h={450}
        type="hover"
        scrollbars="y"
        scrollbarSize={5}
        offsetScrollbars
        pr="xs"
      >
        <Stack>
          <Grid>
            <Grid.Col span={6}>
              <Stack gap="xs">
                <TextInput
                  classNames={global}
                  size="xs"
                  label="Name"
                  description="A unique identifier for this animation"
                  value={tempItem.value}
                  onChange={(e) => updateField("value", e.currentTarget.value)}
                />
                <TextInput
                  classNames={global}
                  size="xs"
                  label="Dictionary"
                  value={tempItem.anim?.dict ?? ""}
                  onChange={(e) => updateAnim("dict", e.currentTarget.value)}
                />
                <NumberInput
                  classNames={global}
                  size="xs"
                  value={tempItem.duration / 1000}
                  label="Duration (in seconds)"
                  onChange={(e) => updateField("duration", Number(e) * 1000)}
                />
              </Stack>
            </Grid.Col>
            <Grid.Col span={6}>
              <Stack gap="xs">
                <TextInput
                  classNames={global}
                  size="xs"
                  label="Progress Label"
                  description="Text to display on progressbar"
                  value={tempItem.label}
                  onChange={(e) => updateField("label", e.currentTarget.value)}
                />
                <TextInput
                  classNames={global}
                  size="xs"
                  label="Animation"
                  value={tempItem.anim?.clip ?? ""}
                  onChange={(e) => updateAnim("clip", e.currentTarget.value)}
                />
              </Stack>
            </Grid.Col>
          </Grid>
          <PropList tempItem={tempItem} updateField={updateField} />
        </Stack>
      </ScrollArea>
      <Group mt="sm">
        <Button
          size="xs"
          ml="auto"
          onClick={() => fetchNui("av_business", "testAnim", tempItem)}
        >
          Preview
        </Button>
        <Button
          className={global.button}
          size="xs"
          onClick={() => handleSave(tempItem)}
          disabled={tempItem.value.length === 0 || tempItem.label.length === 0}
        >
          Save
        </Button>
      </Group>
    </Modal>
  );
};
