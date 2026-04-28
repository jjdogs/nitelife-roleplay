import {
  Stack,
  Group,
  Text,
  Button,
  TextInput,
  ScrollAreaAutosize,
  Table,
  Tooltip,
  ActionIcon,
} from "@mantine/core";
import { useEffect, useState } from "react";
import { AnimType, ApiAnimations } from "./api";
import { Loading } from "../../Loading";
import { fetchNui, isEnvBrowser } from "../../../hooks/useNuiEvents";
import { sortAlphabetically } from "../../../hooks/sortArray";
import { SelectType } from "../../../types/types";
import { TypesInterface } from "../Items/Types/api";
import { IconEdit, IconTrash } from "@tabler/icons-react";
import { Panel } from "./Panel";
import global from "../../../global.module.css";

const Animations = ({
  allJobs,
  itemTypes,
}: {
  allJobs: SelectType[];
  itemTypes: TypesInterface[];
}) => {
  const [loaded, setLoaded] = useState(false);
  const [settings, setSettings] = useState<AnimType[]>([]);
  const [filtered, setFiltered] = useState<AnimType[]>([]);
  const [current, setCurrent] = useState<AnimType | null>(null);
  const [panel, setPanel] = useState(false);

  const handleSearch = (input: string) => {
    const res = settings.filter(
      (item) =>
        (item.value ? item.value.toLowerCase().includes(input) : false) ||
        (item.label ? item.label.toLowerCase().includes(input) : false),
    );
    setFiltered(res);
  };

  const deleteItem = (name: string) => {
    const resp = settings.filter((item) => item.value !== name);
    setSettings(resp);
    setFiltered(resp);
    fetchNui("av_business", "updateSettings", {
      type: "animations",
      settings: resp,
    });
  };

  const handleSave = (item: AnimType) => {
    let updatedSettings = [...settings];
    const exists = settings.some((s) => s.value === item.value);
    if (exists) {
      updatedSettings = settings.map((s) =>
        s.value === item.value ? item : s,
      );
    } else {
      updatedSettings = [...settings, item];
    }
    setSettings(updatedSettings);
    setFiltered(updatedSettings);
    setPanel(false);
    fetchNui("av_business", "updateSettings", {
      type: "animations",
      settings: updatedSettings,
    });
  };

  useEffect(() => {
    const fetchData = async () => {
      const resp = await fetchNui("av_business", "getSettings", "animations");
      if (resp) {
        const sorted: AnimType[] = sortAlphabetically(resp);
        setSettings(sorted);
        setFiltered(sorted);
      } else {
        if (isEnvBrowser()) {
          const sorted: AnimType[] = sortAlphabetically(ApiAnimations);
          setSettings(sorted);
          setFiltered(sorted);
        }
      }
      setTimeout(() => {
        setLoaded(true);
      }, 100);
    };
    fetchData();
  }, []);
  if (!loaded) return <Loading />;
  return (
    <>
      {panel && (
        <Panel
          allJobs={allJobs}
          close={() => {
            setPanel(false);
            setCurrent(null);
          }}
          handleSave={handleSave}
          itemTypes={itemTypes}
          item={current}
        />
      )}
      <Stack>
        <Group>
          <Text
            fz="xs"
            maw={400}
            style={{ wordBreak: "break-word" }}
            c="var(--text-dim)"
            lts={0.55}
          >
            Configure the list of available animations for business items. These
            presets will be accessible to owners when registering new products.
          </Text>
          <Group ml="auto">
            <TextInput
              classNames={global}
              size="xs"
              placeholder="Search..."
              onChange={(e) => {
                handleSearch(e.currentTarget.value);
              }}
            />
            <Button
              className={global.button}
              size="xs"
              onClick={() => {
                setPanel(true);
              }}
            >
              Add Animation
            </Button>
          </Group>
        </Group>
        <ScrollAreaAutosize
          h={470}
          type="hover"
          scrollbars="y"
          scrollbarSize={5}
          mx="auto"
        >
          <Table layout="fixed">
            <Table.Thead>
              <Table.Tr>
                <Table.Th>Name</Table.Th>
                <Table.Th>Label</Table.Th>
                <Table.Th>Types</Table.Th>
                <Table.Th>Job Restricted</Table.Th>
                <Table.Th>Prop</Table.Th>
                <Table.Th>Actions</Table.Th>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {filtered.map((item) => (
                <Table.Tr key={item.value}>
                  <Table.Td>{item.value}</Table.Td>
                  <Table.Td>{item.label}</Table.Td>
                  <Table.Td tt="capitalize">
                    <Text
                      size={item.type.length > 3 ? "xs" : "sm"}
                      c="var(--text-dim)"
                      style={{ wordBreak: "break-word", whiteSpace: "normal" }}
                    >
                      {item.type.length > 0 ? item.type.join(", ") : "No Types"}
                    </Text>
                  </Table.Td>
                  <Table.Td>
                    <Text
                      size="sm"
                      c="var(--text-dim)"
                      style={{ wordBreak: "break-word", whiteSpace: "normal" }}
                    >
                      {item?.jobs ? item.jobs.length > 0 && `Yes` : `No`}
                    </Text>
                  </Table.Td>
                  <Table.Td>{item.prop ? "Yes" : "No"}</Table.Td>
                  <Table.Td>
                    <Group>
                      <Tooltip
                        label="Edit Animation"
                        color="var(--tooltip)"
                        fz="xs"
                      >
                        <ActionIcon
                          size="xs"
                          variant="transparent"
                          color="cyan"
                          onClick={() => {
                            setCurrent(item);
                            setPanel(true);
                          }}
                        >
                          <IconEdit
                            style={{ height: 14, width: 14 }}
                            stroke={1.55}
                          />
                        </ActionIcon>
                      </Tooltip>
                      <Tooltip
                        label="Delete (2 click)"
                        color="var(--tooltip)"
                        fz="xs"
                      >
                        <ActionIcon
                          size="xs"
                          variant="transparent"
                          color="red"
                          onDoubleClick={() => {
                            deleteItem(item.value);
                          }}
                        >
                          <IconTrash
                            style={{ height: 14, width: 14 }}
                            stroke={1.55}
                          />
                        </ActionIcon>
                      </Tooltip>
                    </Group>
                  </Table.Td>
                </Table.Tr>
              ))}
            </Table.Tbody>
          </Table>
        </ScrollAreaAutosize>
      </Stack>
    </>
  );
};

export default Animations;
