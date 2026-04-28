import { useEffect, useState } from "react";
import { Stack, Group, Text } from "@mantine/core";
import { Loading } from "../../../Loading";
import { fetchNui, isEnvBrowser } from "../../../../hooks/useNuiEvents";
import { ApiCustomer, CartItem } from "./api";
import { IngredientsType, SelectType } from "../../../../types/types";
import { ApiIngredients } from "../../../../API/products";
import { DiscountType } from "../../../Business/Discounts/api";
import { useRecoilValue } from "recoil";
import { Lang } from "../../../../reducers/atoms";
import { Content } from "./Content";

export const Customer = ({ job, id }: { job: string; id: string }) => {
  const daLang: any = useRecoilValue(Lang);
  const lang = daLang.cashier;
  const [loaded, setLoaded] = useState(false);
  const [items, setItems] = useState<CartItem[]>([]);
  const [coupon, setCoupon] = useState<DiscountType | undefined>();
  const [code, setCode] = useState<string | null>(null);
  const [inventory, setInventory] = useState("");
  const [customerName, setCustomerName] = useState("");
  const [accounts, setAccounts] = useState<SelectType[]>([]);
  const [account, setAccount] = useState("bank");
  const [ingredients, setIngredients] = useState<IngredientsType[]>([]);
  const [total, setTotal] = useState(0);
  const [itemsTotal, setItemsTotal] = useState(0);

  const getIngredientLabel = (ingredient: string) => {
    const match = ingredients.find((item) => item.value === ingredient);
    return match ? match.label : ingredient;
  };

  const handleCode = async (code: string) => {
    const resp = await fetchNui("av_business", "getCodeData", { code, job });
    if (resp) {
      setCode(code);
      setCoupon(resp);
    }
  };
  const handlePay = async () => {
    setLoaded(false);
    const resp = await fetchNui("av_business", "payOrder", {
      job,
      id,
      customerName,
      account,
      code,
    });
    if (resp) {
      setItems([]);
      setCoupon(undefined);
      setCode("");
    }
    setTimeout(() => {
      setLoaded(true);
    }, 100);
  };

  useEffect(() => {
    const fetchData = async () => {
      const resp = await fetchNui("av_business", "getCashier", {
        job,
        id,
      });
      if (resp) {
        setItems(resp.items);
        setAccounts(resp.accounts);
        setIngredients(resp.ingredients);
        setCoupon(resp.discount);
        setCode(resp.discount?.code ?? null);
        setInventory(resp.inventory);
        setCustomerName(resp.customerName);
      } else {
        if (isEnvBrowser()) {
          setIngredients(ApiIngredients);
          setItems(ApiCustomer.cart);
          setCoupon(ApiCustomer.discount);
          setCode(ApiCustomer?.discount?.code ?? null);
          setAccounts([
            { value: "cash", label: "Cash" },
            { value: "bank", label: "Bank" },
          ]);
        }
      }
      setTimeout(() => {
        setLoaded(true);
      }, 100);
    };
    fetchData();
  }, [job, id]);

  useEffect(() => {
    const { totalPrice, totalItems } = items.reduce(
      (acc, item) => {
        const price = item.price ?? 1;
        const amount = item.amount ?? 1;
        acc.totalPrice += price * amount;
        acc.totalItems += amount;
        return acc;
      },
      { totalPrice: 0, totalItems: 0 },
    );
    setTotal(totalPrice);
    setItemsTotal(totalItems);
  }, [items]);

  if (!loaded) return <Loading />;
  return (
    <>
      <Stack gap="xs">
        <Group p="sm" bg="var(--bg-sidebar)">
          <Group gap="xs">
            <Text fz="md" c="white" fw={500}>
              {lang.header}
            </Text>
            <Text fz="xs">{`#${id.replace(/\D/g, "")}`}</Text>
          </Group>
        </Group>
        <Content
          code={code}
          coupon={coupon}
          daLang={daLang}
          getIngredientLabel={getIngredientLabel}
          handleCode={handleCode}
          handlePay={handlePay}
          inventory={inventory}
          items={items}
          itemsTotal={itemsTotal}
          setCode={() => {
            setCode(null);
            setCoupon(undefined);
          }}
          total={total}
          accounts={accounts}
          account={account}
          setAccount={setAccount}
          customerName={customerName}
          setCustomerName={setCustomerName}
        />
      </Stack>
    </>
  );
};
