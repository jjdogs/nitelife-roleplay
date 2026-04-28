import {
  Grid,
  Text,
  Group,
  TextInput,
  ActionIcon,
  NumberInput,
  Image,
  Card,
  ScrollArea,
  Indicator,
  Stack,
  Flex,
} from "@mantine/core";
import { useState, useEffect } from "react";
import { ApiIngredients } from "../../../API/products";
import { useRecoilValue } from "recoil";
import { Lang } from "../../../reducers/atoms";
import { IconSearch, IconShoppingCart } from "@tabler/icons-react";
import { useDisclosure } from "@mantine/hooks";
import { IngredientsType } from "../../../types/types";
import { Loading } from "../../Loading";
import { fetchNui, isEnvBrowser } from "../../../hooks/useNuiEvents";
import { Cart } from "./Cart";
import classes from "./style.module.css";
import global from "../../../global.module.css";

const Supplies = () => {
  const daLang: any = useRecoilValue(Lang);
  const lang = daLang.supplies;
  const [loaded, setLoaded] = useState(false);
  const [opened, { toggle, close }] = useDisclosure(false);
  const [maxAmount, setMaxAmount] = useState(100);

  const [total, setTotal] = useState(0);
  const [cart, setCart] = useState<(IngredientsType & { amount: number })[]>(
    [],
  );
  const [search, setSearch] = useState("");
  const [allItems, setAllItems] = useState<
    (IngredientsType & { amount?: number })[]
  >([]);
  const [filtered, setFiltered] = useState<
    (IngredientsType & { amount?: number })[]
  >([]);
  const [inventory, setInventory] = useState("");
  const [modified, setModified] = useState<{ [key: string]: boolean }>({});

  const handleCart = (item: IngredientsType, amount: number) => {
    setModified((prev) => ({ ...prev, [item.value]: true }));
    setCart((prevCart) => {
      const exists = prevCart.find((i) => i.value === item.value);
      if (amount === 0) {
        return prevCart.filter((i) => i.value !== item.value);
      }
      if (exists) {
        return prevCart.map((i) =>
          i.value === item.value ? { ...i, amount } : i,
        );
      }
      return [...prevCart, { ...item, amount }];
    });
  };
  const handleSearchChange = (value: string) => {
    setSearch(value);
    const search = value.toLowerCase();
    const res = allItems.filter(
      (item) =>
        (item.label ? item.label.toLowerCase().includes(search) : false) ||
        (item.value ? item.value.toLowerCase().includes(search) : false),
    );
    setFiltered(res);
  };
  const handleBuy = async () => {
    setLoaded(false);
    const resp = await fetchNui("av_business", "buySupplies", cart);
    if (resp) {
      setCart([]);
      setModified({});
    }
    setTimeout(() => {
      setLoaded(true);
    }, 200);
  };
  useEffect(() => {
    const newTotal = cart.reduce((acc, item) => {
      const price = item.price ?? 1;
      return acc + price * item.amount;
    }, 0);
    setTotal(newTotal);
  }, [cart]);

  useEffect(() => {
    const fetchData = async () => {
      const resp = await fetchNui("av_business", "getSupplies");
      if (resp) {
        setAllItems(resp.supplies);
        setFiltered(resp.supplies);
        setInventory(resp.inventory);
        setMaxAmount(resp.maxAmount);
      } else {
        if (isEnvBrowser()) {
          setAllItems(ApiIngredients);
          setFiltered(ApiIngredients);
        }
      }
      setTimeout(() => {
        setLoaded(true);
      }, 200);
    };
    fetchData();
  }, []);
  if (!loaded) return <Loading />;
  return (
    <>
      <Cart
        daLang={daLang}
        opened={opened}
        close={close}
        cart={cart}
        inventory={inventory}
        handleCart={handleCart}
        handleBuy={handleBuy}
        total={total}
      />
      <Group
        bg="var(--bg-card)"
        p="sm"
        style={{
          borderRadius: "6px",
          border: "solid 1px var(--border)",
        }}
      >
        <Flex gap="xs" direction="column">
          <Text ff="var(--font-display)" tt="uppercase" fz="xl" fw={700}>
            {lang.header}
          </Text>
          <Text mt={-15} fz="xs" c="var(--text-dim)">
            {`${filtered.length} ${lang.items}`}
          </Text>
        </Flex>

        <TextInput
          classNames={global}
          placeholder={lang.search}
          leftSection={<IconSearch size={16} stroke={1.5} />}
          value={search}
          onChange={(e) => {
            handleSearchChange(e.currentTarget.value);
          }}
          size="xs"
          ml="auto"
          w={200}
        />
        <Indicator
          color="var(--cyan)"
          inline
          processing
          disabled={cart.length === 0}
        >
          <ActionIcon
            className={classes.button}
            variant="filled"
            w={40}
            onClick={() => {
              toggle();
            }}
          >
            <IconShoppingCart style={{ height: "14px" }} />
          </ActionIcon>
        </Indicator>
      </Group>
      <ScrollArea
        type="hover"
        scrollbars={"y"}
        scrollbarSize={6}
        className={classes.scroll}
        mt="md"
      >
        <Grid gutter="xs">
          {filtered.map((item) => {
            const cartItem = cart.find((i) => i.value === item.value);
            const inputValue = cartItem
              ? cartItem.amount
              : modified[item.value]
                ? 0
                : undefined;
            return (
              <Grid.Col miw={200} maw={200}>
                <Card className={classes.card}>
                  <Stack gap="xs">
                    <Group>
                      <Flex direction="column">
                        <Text
                          fz="sm"
                          maw={100}
                          truncate
                          tt="uppercase"
                          c="var(--text-main)"
                        >
                          {item.label}
                        </Text>
                        <Text
                          fz="sm"
                          ff="var(--font-display)"
                          c="var(--success)"
                        >
                          {`${daLang.money_symbol} ${item.price}`}
                        </Text>
                      </Flex>
                      <Image
                        ml="auto"
                        src={`${`https://cfx-nui-${inventory}${item?.value}.png`}`}
                        fallbackSrc="./item_default.png"
                        w={35}
                        h={35}
                      />
                    </Group>
                    <Group gap={0}>
                      <NumberInput
                        classNames={global}
                        flex={1}
                        hideControls
                        size="xs"
                        value={inputValue}
                        allowDecimal={false}
                        allowLeadingZeros={false}
                        allowNegative={false}
                        max={maxAmount}
                        onChange={(e) => {
                          handleCart(item, Number(e));
                        }}
                        rightSection={
                          <Text mr="xl" fz="xs" c="var(--text-dim)">
                            {lang.quantity}
                          </Text>
                        }
                        styles={{
                          input: {
                            textAlign: "center",
                          },
                        }}
                      />
                    </Group>
                  </Stack>
                </Card>
              </Grid.Col>
            );
          })}
        </Grid>
      </ScrollArea>
    </>
  );
};

export default Supplies;
