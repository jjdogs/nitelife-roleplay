import { useEffect, useState } from "react";
import {
  Table,
  Text,
  Group,
  Image,
  ScrollAreaAutosize,
  ActionIcon,
  Tooltip,
} from "@mantine/core";
import { JobItem } from "../../../../types/types";
import { fetchNui, isEnvBrowser } from "../../../../hooks/useNuiEvents";
import { ApiJobItems } from "../../../../API/products";
import { Loading } from "../../../Loading";
import { sortAlphabetically } from "../../../../hooks/sortArray";
import { IconTrash } from "@tabler/icons-react";
import { useRecoilValue } from "recoil";
import { Lang } from "../../../../reducers/atoms";
import classes from "./style.module.css";

export const Products = ({ job }: { job: string | null }) => {
  if (!job) return null;
  const daLang: any = useRecoilValue(Lang);
  const [loaded, setLoaded] = useState(false);
  const [items, setItems] = useState<JobItem[]>([]);
  const [inventory, setInventory] = useState("");

  const deleteItem = async (name: string) => {
    const resp: JobItem[] | undefined = await fetchNui(
      "av_business",
      "deleteItemAdmin",
      {
        name,
        job,
      },
    );
    if (!resp) return;
    const sorted = sortAlphabetically(resp);
    setItems(sorted);
  };
  useEffect(() => {
    const fetchData = async () => {
      if (!job) return;
      setLoaded(false);
      try {
        const resp = await fetchNui<{ items: JobItem[]; inventory: string }>(
          "av_business",
          "getAdminItems",
          job,
        );
        const rawData = resp?.items || (isEnvBrowser() ? ApiJobItems : []);
        setItems(sortAlphabetically(rawData));
        setInventory(resp.inventory || "");
      } catch (error) {
        console.error("Error fetching admin items:", error);
      } finally {
        setLoaded(true);
      }
    };

    fetchData();
  }, [job]);

  if (!loaded) return <Loading />;
  return (
    <ScrollAreaAutosize
      h={470}
      type="hover"
      scrollbars="y"
      scrollbarSize={5}
      mx="auto"
    >
      <Table layout="fixed" classNames={classes}>
        <Table.Thead>
          <Table.Tr>
            <Table.Th w={200}>Item</Table.Th>
            <Table.Th>Label</Table.Th>
            <Table.Th>Type</Table.Th>
            <Table.Th>Ingredients</Table.Th>
            <Table.Th>Price</Table.Th>
            <Table.Th>Actions</Table.Th>
          </Table.Tr>
        </Table.Thead>
        <Table.Tbody>
          {items.map((item) => (
            <Table.Tr key={item.name}>
              <Table.Td>
                <Tooltip label={item.name} color="dark.6" fz="xs" multiline>
                  <Group gap="xs">
                    <Image
                      src={
                        item.image
                          ? item.image
                          : `${`https://cfx-nui-${inventory}${item?.name}.png`}`
                      }
                      fallbackSrc="./item_default.png"
                      w={40}
                    />
                    <Text fz="xs" truncate maw={100} c="var(--text-main)">
                      {item.name}
                    </Text>
                  </Group>
                </Tooltip>
              </Table.Td>
              <Table.Td>
                <Text fz="xs" truncate maw={155}>
                  {item.label}
                </Text>
              </Table.Td>
              <Table.Td tt="capitalize" fz="xs">
                {item.type}
              </Table.Td>
              <Table.Td>
                <Text
                  size="xs"
                  c="var(--text-dim)"
                  style={{ wordBreak: "break-word", whiteSpace: "normal" }}
                >
                  {item.ingredients.length > 0
                    ? item.ingredients.join(", ")
                    : "No ingredients"}
                </Text>
              </Table.Td>
              <Table.Td
                c="var(--success)"
                ff="var(--font-display)"
              >{`${daLang.money_symbol}${item.price.toLocaleString("en-US")}`}</Table.Td>
              <Table.Td>
                <Tooltip
                  label="Delete Product (2 click)"
                  color="var(--tooltip)"
                  fz="xs"
                >
                  <ActionIcon
                    size="xs"
                    variant="transparent"
                    color="red"
                    onDoubleClick={() => {
                      deleteItem(item.name);
                    }}
                  >
                    <IconTrash
                      style={{ height: 14, width: 14 }}
                      stroke={1.55}
                    />
                  </ActionIcon>
                </Tooltip>
              </Table.Td>
            </Table.Tr>
          ))}
        </Table.Tbody>
      </Table>
    </ScrollAreaAutosize>
  );
};
