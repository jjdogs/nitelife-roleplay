import { useEffect, useState } from "react";
import { Group, Text, Stack, Button } from "@mantine/core";
import { Loading } from "../../../Loading";
import {
  IngredientsType,
  JobItem,
  ModalType,
  SelectType,
} from "../../../../types/types";
import { fetchNui, isEnvBrowser } from "../../../../hooks/useNuiEvents";
import {
  ApiIngredients,
  ApiJobItems,
  ApiTypes,
} from "../../../../API/products";
import { useRecoilValue } from "recoil";
import { Lang } from "../../../../reducers/atoms";
import { IconShoppingCart, IconArrowBackUp } from "@tabler/icons-react";
import { ModalMenu } from "../../../ModalMenu/ModalMenu";
import { Front } from "./Front";
import { Cart } from "./Cart";
import { DiscountType } from "../../../Business/Discounts/api";
import global from "../../../../global.module.css";

interface ItemType extends JobItem {
  toUse: string[];
}

export const Employee = ({ job, id }: { job: string; id: string }) => {
  const daLang: any = useRecoilValue(Lang);
  const lang = daLang.cashier;
  const [loaded, setLoaded] = useState(false);
  const [allIngredients, setAllIngredients] = useState<IngredientsType[]>([]);
  const [allTypes, setAllTypes] = useState<SelectType[]>([]);
  const [allItems, setAllItems] = useState<ItemType[] | JobItem[]>([]);
  const [filtered, setFiltered] = useState<ItemType[] | JobItem[]>([]);
  const [inventory, setInventory] = useState("");
  const [cart, setCart] = useState<ItemType[]>([]);
  const [filteredCart, setFilteredCart] = useState<ItemType[] | JobItem[]>([]);
  const [itemsTotal, setItemsTotal] = useState(0);
  const [total, setTotal] = useState(0);
  const [showCart, setShowCart] = useState(false);
  const [coupon, setCoupon] = useState<DiscountType | null>(null);
  const [code, setCode] = useState<string | null>(null);

  const [modal, setModal] = useState<ModalType>({
    state: false,
    portal: false,
    info: {
      title: "",
      options: [],
    },
  });

  const handleCode = async (code: string) => {
    const resp = await fetchNui("av_business", "getCodeData", { code, job });
    if (resp) {
      setCode(code);
      setCoupon(resp);
    }
  };

  const getIngredientLabel = (ingredient: string) => {
    const match = allIngredients.find((item) => item.value === ingredient);
    return match ? match.label : ingredient;
  };

  const handleSearch = (input: string) => {
    const res = allItems.filter(
      (item) =>
        (item.name ? item.name.toLowerCase().includes(input) : false) ||
        (item.label ? item.label.toLowerCase().includes(input) : false),
    );
    setFiltered(res);
  };

  const usingIngredient = (name: string, ingredients: string[] | undefined) => {
    if (!ingredients) return false;
    return ingredients.find((item) => item === name);
  };

  const handleIngredient = (
    item: string,
    ingredient: string,
    index: number,
  ) => {
    const toggleIngredient = (items: typeof allItems) =>
      items.map((i, idx) => {
        if (i.name !== item || idx !== index) return i;
        const toUse = i.toUse || [];
        const updatedToUse = toUse.includes(ingredient)
          ? toUse.filter((val) => val !== ingredient)
          : [...toUse, ingredient];
        return { ...i, toUse: updatedToUse };
      });

    setAllItems((prev) => toggleIngredient(prev));
    setFiltered((prev) => toggleIngredient(prev));
  };
  const handleCart = (item: any, type: string, index: number) => {
    if (type === "add") {
      setModal({
        ...modal,
        state: true,
        info: {
          title: item.label,
          options: [
            { type: "number", name: "amount", title: lang.to_add, max: 99 },
          ],
          extraData: item,
          button: daLang.confirm_button,
        },
      });
    } else {
      setCart((prev) => {
        const copy = [...prev];
        const targetIndex = copy.findIndex(
          (i, idx) => i.name === item.name && idx === index,
        );
        if (targetIndex !== -1) copy.splice(targetIndex, 1);
        return copy;
      });

      setFilteredCart((prev) => {
        const copy = [...prev];
        const targetIndex = copy.findIndex(
          (i, idx) => i.name === item.name && idx === index,
        );
        if (targetIndex !== -1) copy.splice(targetIndex, 1);
        return copy;
      });
    }
  };

  const handleFilter = (type: string | null) => {
    if (!type) {
      setFiltered(allItems);
    } else {
      const res = allItems.filter((item) =>
        item.type ? item.type.toLowerCase().includes(type) : false,
      );
      setFiltered(res);
    }
  };

  const callback = (data: any) => {
    setModal({ ...modal, state: false });
    if (!data) return;
    if (data.amount <= 0 || data.amount > 999) return;
    const itemData = { ...data.extraData, amount: data.amount ?? 1 };
    setCart([...cart, itemData]);
    setFilteredCart([...filteredCart, itemData]);
  };

  const toggleCart = () => {
    setShowCart(!showCart);
  };

  const handleRemove = (name: string, index: number) => {
    setCart((prev) => {
      const copy = [...prev];
      const targetIndex = copy.findIndex(
        (i, idx) => i.name === name && idx === index,
      );
      if (targetIndex !== -1) copy.splice(targetIndex, 1);
      return copy;
    });

    setFilteredCart((prev) => {
      const copy = [...prev];
      const targetIndex = copy.findIndex(
        (i, idx) => i.name === name && idx === index,
      );
      if (targetIndex !== -1) copy.splice(targetIndex, 1);
      return copy;
    });
  };

  const handleOrder = async () => {
    const resp = await fetchNui("av_business", "sendOrder", {
      id,
      job,
      cart,
      code,
    });
    if (!resp) return;
    setCode(null);
    setCoupon(null);
    setCart([]);
  };

  useEffect(() => {
    const fetchData = async () => {
      const resp = await fetchNui("av_business", "getJobCashier", {
        job,
        id,
      });
      if (resp) {
        setAllIngredients(resp.ingredients);
        setAllItems(resp.items);
        setFiltered(resp.items);
        setAllTypes(resp.types);
        setInventory(resp.inventory);
      } else {
        if (isEnvBrowser()) {
          setAllIngredients(ApiIngredients);
          setAllTypes(ApiTypes);
          setAllItems(ApiJobItems);
          setFiltered(ApiJobItems);
        }
      }
      setTimeout(() => {
        setLoaded(true);
      }, 100);
    };
    fetchData();
  }, []);
  useEffect(() => {
    const { totalPrice, totalItems } = cart.reduce(
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
  }, [cart]);

  if (!loaded) return <Loading />;
  return (
    <>
      {modal.state && <ModalMenu data={modal} callback={callback} />}
      <Stack gap="xs" w={showCart ? 650 : "auto"}>
        <Group p="sm" bg="var(--bg-sidebar)">
          <Group gap="xs">
            <Text fz="md" c="var(--text-main)" fw={500}>
              {lang.header}
            </Text>
            <Text
              fz="xs"
              c="var(--text-dim)"
            >{`#${id.replace(/\D/g, "")}`}</Text>
          </Group>
          <Button className={global.button} ml="auto" onClick={toggleCart}>
            {showCart ? (
              <>
                <IconArrowBackUp
                  style={{ height: 16, width: 16 }}
                  color="var(--text-main)"
                />
                <Text fz="xs" ml="xs">
                  Back to products
                </Text>
              </>
            ) : (
              <>
                <IconShoppingCart
                  style={{ height: 16, width: 16 }}
                  color="var(--text-main)"
                />
                <Text fz="xs" ml="xs">
                  {itemsTotal > 0 ? `${itemsTotal} Product(s)` : `Empty`}
                </Text>
              </>
            )}
          </Button>
        </Group>
        {showCart ? (
          <Cart
            cart={cart}
            inventory={inventory}
            total={total}
            itemsTotal={itemsTotal}
            allTypes={allTypes}
            code={code}
            coupon={coupon}
            handleCode={handleCode}
            handleRemove={handleRemove}
            getIngredientLabel={getIngredientLabel}
            handleOrder={handleOrder}
            setCode={() => {
              setCode(null);
              setCoupon(null);
            }}
          />
        ) : (
          <Front
            filtered={filtered}
            getIngredientLabel={getIngredientLabel}
            handleCart={handleCart}
            handleIngredient={handleIngredient}
            inventory={inventory}
            usingIngredient={usingIngredient}
            allTypes={allTypes}
            handleFilter={handleFilter}
            handleSearch={handleSearch}
          />
        )}
      </Stack>
    </>
  );
};
