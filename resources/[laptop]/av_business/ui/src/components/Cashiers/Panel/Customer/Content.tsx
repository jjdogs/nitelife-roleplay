import {
  Grid,
  Group,
  ScrollAreaAutosize,
  Text,
  Stack,
  Flex,
  Image,
  Divider,
  ActionIcon,
  TextInput,
  Button,
  Select,
} from "@mantine/core";
import { CartItem } from "./api";
import { DiscountType } from "../../../Business/Discounts/api";
import { IconX } from "@tabler/icons-react";
import { useState } from "react";
import { SelectType } from "../../../../types/types";
import global from "../../../../global.module.css";
import classes from "./style.module.css";

interface Properties {
  items: CartItem[];
  inventory: string;
  daLang: any;
  getIngredientLabel: (ingredient: string) => string;
  itemsTotal: number;
  total: number;
  coupon: DiscountType | undefined;
  code: string | null;
  setCode: () => void;
  handleCode: (code: string) => void;
  handlePay: () => void;
  accounts: SelectType[];
  setAccount: (option: string) => void;
  customerName: string;
  setCustomerName: (name: string) => void;
  account: string;
}

export const Content = ({
  items,
  inventory,
  daLang,
  getIngredientLabel,
  itemsTotal,
  total,
  coupon,
  code,
  setCode,
  handleCode,
  handlePay,
  accounts,
  setAccount,
  customerName,
  account,
  setCustomerName,
}: Properties) => {
  const lang: any = daLang.cashier;
  const [tempCode, setTempCode] = useState("");

  return (
    <>
      <Grid>
        <Grid.Col span={7}>
          <ScrollAreaAutosize
            mah={530}
            type="hover"
            scrollbars="y"
            scrollbarSize={5}
            pl="xs"
            pr="xs"
            pb="sm"
          >
            <Stack gap="xs">
              {items.map((item) => (
                <Group className={classes.card} p="xs">
                  <Image
                    src={`${`https://cfx-nui-${inventory}${item?.name}.png`}`}
                    fallbackSrc="./item_default.png"
                    h={32}
                    w={32}
                    fit="contain"
                  />
                  <Flex direction="column">
                    <Text fz="sm" c="var(--text-main)">
                      {item.label}
                    </Text>
                    <Group gap="xs">
                      <Text
                        fz="sm"
                        ff="var(--font-display)"
                        c="var(--success)"
                        lh={0}
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
                    <Group gap={2} maw={250}>
                      <Text
                        fz="xs"
                        c="var(--text-normal)"
                        fw={450}
                      >{`${lang.ingredients}:`}</Text>
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
                    </Group>
                  </Flex>
                </Group>
              ))}
            </Stack>
          </ScrollAreaAutosize>
        </Grid.Col>
        <Grid.Col span="auto">
          <Stack gap="xs" p="sm">
            <Divider label={lang.total} labelPosition="center" />
            <Stack gap="xs">
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
                <Group>
                  <TextInput
                    classNames={global}
                    size="xs"
                    placeholder={lang.discount_code}
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
            <Stack gap="xs">
              <Divider label={lang.customer_subheader} labelPosition="center" />
              <TextInput
                classNames={global}
                size="xs"
                label={lang.customer_name}
                value={customerName}
                maxLength={30}
                onChange={(e) => {
                  setCustomerName(e.currentTarget.value);
                }}
              />
              <Select
                classNames={global}
                size="xs"
                label={lang.payment_method}
                data={accounts}
                value={account}
                onChange={(e) => {
                  if (!e) return;
                  setAccount(e);
                }}
                allowDeselect={false}
              />
            </Stack>
            <Stack gap="xs" mt="xl">
              <Group justify="space-between">
                <Text fz="xs" c="var(--text-dim)" tt="uppercase" fw={600}>
                  {lang.total}:
                </Text>
                <Text
                  fz="md"
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
                disabled={items.length == 0}
                fullWidth
                onClick={handlePay}
              >
                {lang.complete_button}
              </Button>
            </Stack>
          </Stack>
        </Grid.Col>
      </Grid>
    </>
  );
};
