import { useEffect, useState } from "react";
import {
  Grid,
  Group,
  Stack,
  Text,
  Select,
  TextInput,
  Flex,
  ScrollAreaAutosize,
  Image,
  ActionIcon,
  Divider,
  Button,
} from "@mantine/core";
import { JobItem, SelectType } from "../../../../types/types";
import { useRecoilValue } from "recoil";
import { Lang } from "../../../../reducers/atoms";
import { IconX } from "@tabler/icons-react";
import global from "../../../../global.module.css";
import classes from "./style.module.css";
import { DiscountType } from "../../../Business/Discounts/api";

interface ItemType extends JobItem {
  toUse: string[];
}

interface Properties {
  cart: ItemType[];
  inventory: string;
  total: number;
  itemsTotal: number;
  allTypes: SelectType[];
  coupon?: DiscountType | null;
  code?: string | null;
  handleCode: (input: string) => void;
  setCode: () => void;
  handleRemove: (name: string, index: number) => void;
  getIngredientLabel: (ingredient: string) => string;
  handleOrder: () => void;
}

export const Cart = ({
  cart,
  inventory,
  total,
  coupon,
  code,
  itemsTotal,
  allTypes,
  handleCode,
  setCode,
  handleRemove,
  getIngredientLabel,
  handleOrder,
}: Properties) => {
  const daLang: any = useRecoilValue(Lang);
  const lang = daLang.cashier;
  const [filtered, setFiltered] = useState(cart);
  const [tempCode, setTempCode] = useState("");

  const handleSearch = (input: string) => {
    const res = cart.filter(
      (item) =>
        (item.name ? item.name.toLowerCase().includes(input) : false) ||
        (item.label ? item.label.toLowerCase().includes(input) : false),
    );
    setFiltered(res);
  };

  const handleFilter = (type: string | null) => {
    if (!type) {
      setFiltered(cart);
    } else {
      const res = cart.filter((item) =>
        item.type ? item.type.toLowerCase().includes(type) : false,
      );
      setFiltered(res);
    }
  };

  useEffect(() => {
    setFiltered(cart);
  }, [cart]);

  return (
    <>
      <Grid>
        <Grid.Col span={6}>
          <Group p="xs">
            <Group grow w="100%">
              <Select
                classNames={global}
                size="xs"
                placeholder={lang.filter_type}
                data={allTypes}
                searchable
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
          <ScrollAreaAutosize
            h={475}
            type="hover"
            scrollbars="y"
            scrollbarSize={5}
            pl="xs"
            pr="xs"
            pb="sm"
          >
            <Stack gap="xs">
              {filtered.map((item, index) => (
                <Flex
                  direction="column"
                  className={classes.card}
                  p="xs"
                  gap={5}
                >
                  <Group>
                    <Image
                      src={`${`https://cfx-nui-${inventory}${item?.name}.png`}`}
                      fallbackSrc="./item_default.png"
                      h={32}
                      w={32}
                      fit="contain"
                    />
                    <Flex direction="column">
                      <Text fz="sm" c="gray.1">
                        {item.label}
                      </Text>
                      <Group gap="xs">
                        <Text
                          fz="sm"
                          c="var(--success)"
                          ff="var(--font-display)"
                          fw={450}
                        >{`${daLang.money_symbol}${item.price.toLocaleString("en-US")}`}</Text>
                        <Group gap={2}>
                          <Text fz="xs" c="var(--text-dim)" fw={450}>
                            {lang.amount}:
                          </Text>
                          <Text fz="xs" c="var(--text-normal)" fw={450}>
                            {item.amount}
                          </Text>
                        </Group>
                      </Group>
                    </Flex>
                    <ActionIcon
                      ml="auto"
                      variant="transparent"
                      color="var(--danger)"
                      size="xs"
                      onClick={() => {
                        handleRemove(item.name, index);
                      }}
                    >
                      <IconX style={{ height: 14, width: 14 }} stroke={1.5} />
                    </ActionIcon>
                  </Group>
                  {item.toUse?.length && item.toUse.length > 0 && (
                    <Text
                      fz="xs"
                      c="var(--text-dim)"
                      fw={450}
                      style={{
                        wordBreak: "break-word",
                        whiteSpace: "normal",
                      }}
                    >
                      {item.toUse?.length && item.toUse.length > 0
                        ? item.toUse
                            .map((name) => getIngredientLabel(name))
                            .join(", ")
                        : "No"}
                    </Text>
                  )}
                </Flex>
              ))}
            </Stack>
          </ScrollAreaAutosize>
        </Grid.Col>
        <Grid.Col span="auto">
          <Stack gap="xs" p="sm">
            <Divider label={lang.total} labelPosition="center" />
            <Stack gap="xs" style={{ flex: 1 }}>
              <Group justify="space-between">
                <Text fz="xs" c="var(--text-dim)" tt="uppercase" fw={600}>
                  {lang.products_subheader}:
                </Text>
                <Text fz="sm" fw={600} c="var(--primary-200)">
                  {itemsTotal}
                </Text>
              </Group>
              <Group justify="space-between">
                <Text fz="xs" c="var(--text-dim)" tt="uppercase" fw={600}>
                  {lang.subtotal}:
                </Text>
                <Text fz="md" fw={600} c="var(--cyan)" ff="var(--font-display)">
                  {`${daLang.money_symbol}${total.toLocaleString("en-US")}`}
                </Text>
              </Group>
              <Group justify="space-between">
                <Text fz="xs" c="var(--text-dim)" tt="uppercase" fw={600}>
                  {lang.discounts}:
                </Text>
                <Text fz="sm" fw={600} c="var(--primary-200)">
                  {coupon
                    ? coupon.type === "percentage"
                      ? `${coupon.discount}%`
                      : `${daLang.money_symbol}${coupon.discount}`
                    : "N/A"}
                </Text>
              </Group>
              {code ? (
                <Group>
                  <Text fz="xs" c="var(--text-dim)">
                    {lang.code}:
                  </Text>
                  <Group ml="auto" gap={2}>
                    <Text fz="xs" c="var(--text-dim)">
                      {code}
                    </Text>
                    <ActionIcon
                      size="xs"
                      variant="transparent"
                      color="red"
                      onClick={() => {
                        setCode();
                      }}
                    >
                      <IconX style={{ height: 12, width: 12 }} stroke={1.5} />
                    </ActionIcon>
                  </Group>
                </Group>
              ) : (
                <Group mt="xs">
                  <TextInput
                    classNames={global}
                    size="xs"
                    placeholder={lang.discounts}
                    maxLength={50}
                    flex={1}
                    value={tempCode}
                    onChange={(e) => {
                      setTempCode(e.currentTarget.value);
                    }}
                  />
                  <Button
                    size="xs"
                    className={classes.button}
                    onClick={() => {
                      handleCode(tempCode);
                    }}
                  >
                    {lang.apply}
                  </Button>
                </Group>
              )}
            </Stack>
            <Stack gap="sm" mt="xl">
              <Group justify="space-between">
                <Text fz="xs" c="var(--text-dim)" tt="uppercase" fw={600}>
                  {lang.total}:
                </Text>
                <Text
                  fz="lg"
                  fw={600}
                  c="var(--success)"
                  ff="var(--font-display)"
                >
                  {`${daLang.money_symbol}${Math.max(
                    0,
                    Math.round(
                      coupon?.type === "amount"
                        ? total - (coupon?.discount ?? 0)
                        : total * (1 - (coupon?.discount ?? 0) / 100),
                    ),
                  ).toLocaleString("en-US")}`}
                </Text>
              </Group>
              <Button
                className={classes.button}
                size="xs"
                disabled={cart.length == 0}
                fullWidth
                onClick={handleOrder}
              >
                {lang.send_order}
              </Button>
            </Stack>
          </Stack>
        </Grid.Col>
      </Grid>
    </>
  );
};
