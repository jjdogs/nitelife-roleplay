import {
  Grid,
  Group,
  Text,
  Select,
  TextInput,
  ScrollArea,
} from "@mantine/core";
import { ItemCard } from "./ItemCard";
import { useRecoilValue } from "recoil";
import { Lang } from "../../../../reducers/atoms";
import { JobItem, SelectType } from "../../../../types/types";
import global from "../../../../global.module.css";

interface ItemType extends JobItem {
  toUse: string[];
}

interface Properties {
  inventory: string;
  filtered: ItemType[] | JobItem[];
  allTypes: SelectType[];
  handleFilter: (input: string | null) => void;
  handleSearch: (input: string) => void;
  getIngredientLabel: (ingredient: string) => string;
  usingIngredient: (
    ingredient: string,
    toUse: string[] | undefined,
  ) => string | boolean | undefined;
  handleIngredient: (name: string, ingredient: string, index: number) => void;
  handleCart: (
    product: ItemType | JobItem,
    type: string,
    index: number,
  ) => void;
}

export const Front = ({
  inventory,
  filtered,
  getIngredientLabel,
  handleIngredient,
  handleCart,
  usingIngredient,
  handleFilter,
  handleSearch,
  allTypes,
}: Properties) => {
  const daLang: any = useRecoilValue(Lang);
  const lang = daLang.cashier;
  return (
    <>
      <Group p="xs">
        <Text
          fz="xl"
          lh={0}
          fw={500}
          c="var(--text-main)"
          ff="var(--font-display)"
        >{`${filtered.length} ${daLang.products.products}`}</Text>
        <Group ml="auto">
          <Select
            classNames={global}
            size="xs"
            placeholder={lang.filter_type}
            data={allTypes}
            searchable
            w={140}
            onChange={(e) => {
              handleFilter(e);
            }}
          />
          <TextInput
            classNames={global}
            size="xs"
            placeholder={daLang.search}
            onChange={(e) => {
              handleSearch(e.currentTarget.value);
            }}
          />
        </Group>
      </Group>
      <ScrollArea
        h={470}
        type="hover"
        scrollbars="y"
        scrollbarSize={5}
        pl="xs"
        pr="xs"
        pb="sm"
      >
        <Grid gutter="sm" w={600}>
          {filtered.map((item, index) => (
            <Grid.Col
              key={`${item.name}-${index}`}
              span="auto"
              miw={200}
              maw={200}
            >
              <ItemCard
                daLang={daLang}
                getIngredientLabel={getIngredientLabel}
                index={index}
                inventory={inventory}
                isCart={false}
                handleIngredient={handleIngredient}
                handleCart={handleCart}
                product={item}
                usingIngredient={usingIngredient}
              />
            </Grid.Col>
          ))}
        </Grid>
      </ScrollArea>
    </>
  );
};
