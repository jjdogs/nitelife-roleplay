import {
  Group,
  Text,
  Grid,
  ScrollArea,
  Switch,
  Checkbox,
  TextInput,
  ActionIcon,
  Tooltip,
  Flex,
} from "@mantine/core";
import { DeliveriesMap } from "./DeliveriesMap";
import { useEffect, useState } from "react";
import {
  fetchNui,
  isEnvBrowser,
  useNuiEvent,
} from "../../../hooks/useNuiEvents";
import { ApiDeliveries, ApiDelivery } from "../../../API/delivery";
import { DeliveryType } from "../../../types/types";
import { useRecoilValue } from "recoil";
import { Lang } from "../../../reducers/atoms";
import { OrderCard } from "./OrderCard";
import classes from "./style.module.css";
import global from "../../../global.module.css";
import { Details } from "./Details";
import { useViewportSize } from "@mantine/hooks";
import { Loading } from "../../Loading";
import { IconClipboardList } from "@tabler/icons-react";
import { ItemsList } from "./ItemsList";

interface OrderType {
  state: boolean;
  order: DeliveryType;
}

const Deliveries = () => {
  const daLang: any = useRecoilValue(Lang);
  const lang = daLang.deliveries;
  const [loaded, setLoaded] = useState(false);
  const [allDeliveries, setAllDeliveries] = useState<DeliveryType[]>([]);
  const [filtered, setFiltered] = useState<DeliveryType[]>([]);
  const [open, setOpen] = useState(false);
  const [notify, setNotify] = useState(false);
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<string[]>([]);
  const [myCoords, setMyCoords] = useState({ x: 0, y: 0 });
  const [myIdentifier, setMyIdentifier] = useState("");
  const [showDetails, setShowDetails] = useState<OrderType>({
    state: false,
    order: ApiDelivery,
  });
  const [showList, setShowList] = useState(false);
  const { height } = useViewportSize();

  const fetchData = async () => {
    const resp = await fetchNui("av_business", "getDeliveries");
    if (resp) {
      setAllDeliveries(resp.deliveries);
      setFiltered(resp.deliveries);
      setOpen(resp.isOpen);
      setNotify(resp.notify);
      setMyCoords(resp.coords);
      setMyIdentifier(resp.myIdentifier);
    } else {
      if (isEnvBrowser()) {
        setAllDeliveries(ApiDeliveries);
        setFiltered(ApiDeliveries);
      }
    }
    if (!loaded) {
      setTimeout(() => {
        setLoaded(true);
      }, 200);
    }
  };
  useNuiEvent("updateDeliveries", () => {
    fetchData();
  });
  const handleOrder = (event: string, order: DeliveryType) => {
    fetchNui("av_business", event, order);
  };
  const handleSearch = (value: string) => {
    setSearch(value);
    const search = value.toLowerCase();
    const res = allDeliveries.filter(
      (item) =>
        (item.identifier
          ? item.identifier.toLowerCase().includes(search)
          : false) ||
        (item.claimed ? item.claimed.toLowerCase().includes(search) : false),
    );
    setFiltered(res);
  };

  const handleDetails = (order: DeliveryType) => {
    setShowDetails({
      state: true,
      order,
    });
  };

  const handleSelection = (identifier: string) => {
    setSelected((prev) =>
      prev.includes(identifier)
        ? prev.filter((id) => id !== identifier)
        : [...prev, identifier],
    );
  };
  useEffect(() => {
    fetchData();
  }, []);
  if (!loaded) return <Loading />;
  return (
    <>
      {showDetails.state && (
        <Details
          daLang={daLang}
          order={showDetails.order}
          setShow={() => {
            setShowDetails({ ...showDetails, state: false });
          }}
        />
      )}
      {showList && <ItemsList setItemPanel={setShowList} lang={lang} />}
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
            {`${allDeliveries.length} Orders`}
          </Text>
        </Flex>
        <Group ml="auto">
          <Switch
            checked={open}
            labelPosition="left"
            label={lang.orders}
            color="var(--accent)"
            size="xs"
            onChange={(e) => {
              setOpen(e.currentTarget.checked);
              fetchNui(
                "av_business",
                "toggleDeliveries",
                e.currentTarget.checked,
              );
            }}
          />
          <Checkbox
            labelPosition="left"
            checked={notify}
            label={lang.notify}
            color="var(--accent)"
            onChange={(e) => {
              setNotify(e.currentTarget.checked);
              fetchNui("av_business", "notifyme", e.currentTarget.checked);
            }}
            size="xs"
          />
          <Tooltip
            label={lang.inventory_header}
            color="var(--tooltip)"
            fz="xs"
            withArrow
          >
            <ActionIcon
              size="md"
              variant="transparent"
              color="var(--cyan)"
              onClick={() => {
                setShowList(!showList);
              }}
            >
              <IconClipboardList size={20} />
            </ActionIcon>
          </Tooltip>
          <TextInput
            classNames={global}
            placeholder={daLang.search}
            value={search}
            onChange={(e) => {
              handleSearch(e.currentTarget.value);
            }}
            size="xs"
            w={200}
          />
        </Group>
      </Group>
      <Grid mt="md" gutter="xs">
        <Grid.Col span={height > 800 ? 6 : 4}>
          <ScrollArea
            className={classes.scroll}
            offsetScrollbars
            type="hover"
            scrollbars={"y"}
            scrollbarSize={6}
          >
            <Grid grow={filtered.length > 0}>
              {[...filtered]
                .sort((a, b) => {
                  const aIsMine = a.claimedIdentifier === myIdentifier;
                  const bIsMine = b.claimedIdentifier === myIdentifier;
                  return Number(bIsMine) - Number(aIsMine);
                })
                .map((order) => (
                  <Grid.Col span={5} miw={240} key={order.identifier}>
                    <OrderCard
                      data={order}
                      symbol={daLang.money_symbol ?? "$"}
                      handleDetails={handleDetails}
                      selected={selected.includes(order.identifier)}
                      handleOrder={handleOrder}
                      daLang={daLang}
                    />
                  </Grid.Col>
                ))}
            </Grid>
          </ScrollArea>
        </Grid.Col>
        <Grid.Col
          span={height > 800 ? 6 : 7}
          className={classes.scroll}
          h={isEnvBrowser() ? 755 : undefined}
        >
          <DeliveriesMap
            orders={allDeliveries}
            setSelected={handleSelection}
            myCoords={myCoords}
            myIdentifier={myIdentifier}
            daLang={daLang}
          />
        </Grid.Col>
      </Grid>
    </>
  );
};

export default Deliveries;
