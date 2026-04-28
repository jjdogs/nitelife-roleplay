import { useEffect, useState } from "react";
import {
  Stack,
  Table,
  ScrollArea,
  TextInput,
  Group,
  Text,
  Button,
  Select,
  ActionIcon,
  Flex,
  Badge,
} from "@mantine/core";
import { fetchNui, isEnvBrowser } from "../../../hooks/useNuiEvents";
import { ApiDiscounts, DiscountType } from "./api";
import { IconCopy } from "@tabler/icons-react";
import { Loading } from "../../Loading";
import { sortAlphabetically, sortData } from "./utils";
import { TableHeader } from "../../TableHeader/TableHeader";
import { Panel } from "./Panel";
import { isWide } from "../../../hooks/wide";
import { Creator } from "./Creator";
import { useRecoilValue } from "recoil";
import { Lang } from "../../../reducers/atoms";
import global from "../../../global.module.css";
import classes from "./style.module.css";

const Discounts = () => {
  const daLang: any = useRecoilValue(Lang);
  const lang = daLang.discounts;
  const [loaded, setLoaded] = useState(false);
  const [allDiscounts, setAllDiscounts] = useState<DiscountType[]>([]);
  const [filtered, setFiltered] = useState<DiscountType[]>([]);
  const [sortBy, setSortBy] = useState<keyof DiscountType | null>(null);
  const [search, setSearch] = useState("");
  const [reverseSortDirection, setReverseSortDirection] = useState(false);
  const [item, setItem] = useState<DiscountType | null>(null);
  const [showCreator, setShowCreator] = useState(false);
  const wide = isWide();

  const setSorting = (field: keyof DiscountType) => {
    const reversed = field === sortBy ? !reverseSortDirection : false;
    setReverseSortDirection(reversed);
    setSortBy(field);
    setFiltered(sortData(filtered, { sortBy: field, reversed, search }));
  };

  const handleSearch = (input: string) => {
    const query = input.toLowerCase().trim();
    setSearch(query);
    if (query === "") {
      setFiltered(allDiscounts);
      return;
    }
    const results = filtered.filter(
      (item) =>
        item.code.toLowerCase().includes(query) ||
        item.employee.toLowerCase().includes(query) ||
        item.description.toLowerCase().includes(query),
    );
    setFiltered(results);
  };

  const handleDelete = (code: string) => {
    fetchNui("av_business", "deleteCoupon", code);
    const updatedList = allDiscounts.filter((item) => item.code !== code);
    setAllDiscounts(updatedList);
    setFiltered(updatedList);
    setItem(null);
  };

  const toggleStatus = (code: string) => {
    const currentCoupon = allDiscounts.find((c) => c.code === code);
    if (!currentCoupon) return;
    const newStatus = !currentCoupon.enabled;
    fetchNui("av_business", "toggleCoupon", {
      code: code,
      status: newStatus,
    });
    const updateList = (prev: DiscountType[]) =>
      prev.map((item) =>
        item.code === code ? { ...item, enabled: newStatus } : item,
      );
    setAllDiscounts(updateList);
    setFiltered(updateList);
    setItem((prev) => {
      if (prev?.code === code) {
        return { ...prev, enabled: newStatus };
      }
      return prev;
    });
  };

  const handleFilter = (value: string | null) => {
    setSearch("");
    if (!value) {
      setFiltered(allDiscounts);
      return;
    }

    const results = allDiscounts.filter((item) => {
      switch (value) {
        case "active":
          return item.enabled;
        case "inactive":
          return !item.enabled;
        case "percentage":
          return item.type === "percentage";
        case "amount":
          return item.type === "amount";
        default:
          return true;
      }
    });
    setFiltered(results);
  };

  const handleCreator = async (refresh: boolean) => {
    setShowCreator(false);
    if (!refresh) return;
    fetchData();
  };

  const fetchData = async () => {
    setLoaded(false);
    const resp = await fetchNui("av_business", "getDiscounts");
    const data: DiscountType[] = resp || (isEnvBrowser() ? ApiDiscounts : []);
    const sorted = sortAlphabetically(data);
    setAllDiscounts(sorted);
    setFiltered(sorted);
    setTimeout(() => setLoaded(true), 100);
  };
  useEffect(() => {
    fetchData();
  }, []);

  if (!loaded) return <Loading />;

  return (
    <>
      {item && (
        <Panel
          coupon={item}
          handleClose={() => setItem(null)}
          handleDelete={handleDelete}
          toggleStatus={toggleStatus}
          lang={lang}
        />
      )}
      {showCreator && <Creator handleCreator={handleCreator} />}
      <Stack gap="xs">
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
              {`${filtered.length} ${lang.coupons}`}
            </Text>
          </Flex>
          <Group ml="auto">
            <Select
              classNames={global}
              size="xs"
              placeholder="Filter by"
              w={wide ? "unset" : 135}
              data={[
                { value: "active", label: lang.active },
                { value: "inactive", label: lang.inactive },
                { value: "percentage", label: lang.percentage },
                { value: "amount", label: lang.amount },
              ]}
              onChange={handleFilter}
              clearable
            />
            <TextInput
              classNames={global}
              size="xs"
              w={wide ? "unset" : 135}
              placeholder={daLang.search}
              value={search}
              onChange={(e) => handleSearch(e.currentTarget.value)}
            />
            <Button
              size="xs"
              className={global.button}
              onClick={() => {
                setShowCreator(true);
              }}
            >
              {lang.new_coupon}
            </Button>
          </Group>
        </Group>

        <ScrollArea
          type="hover"
          scrollbars="y"
          scrollbarSize={6}
          className={classes.scroll}
        >
          <Table
            classNames={classes}
            layout="auto"
            highlightOnHover
            highlightOnHoverColor="rgba(100,100,100,1)"
          >
            <Table.Thead>
              <Table.Tr>
                <TableHeader
                  sorted={sortBy === "code"}
                  reversed={reverseSortDirection}
                  onSort={() => setSorting("code")}
                >
                  {lang.code}
                </TableHeader>
                {wide && (
                  <TableHeader
                    sorted={sortBy === "description"}
                    reversed={reverseSortDirection}
                    onSort={() => setSorting("description")}
                  >
                    {lang.description}
                  </TableHeader>
                )}
                <TableHeader
                  sorted={sortBy === "discount"}
                  reversed={reverseSortDirection}
                  onSort={() => setSorting("discount")}
                >
                  {lang.discount}
                </TableHeader>
                {wide && (
                  <TableHeader
                    sorted={sortBy === "employee"}
                    reversed={reverseSortDirection}
                    onSort={() => setSorting("employee")}
                  >
                    {lang.created_by}
                  </TableHeader>
                )}
                <TableHeader
                  sorted={sortBy === "redeemed"}
                  reversed={reverseSortDirection}
                  onSort={() => setSorting("redeemed")}
                >
                  {lang.redeemed}
                </TableHeader>
                <TableHeader
                  sorted={sortBy === "enabled"}
                  reversed={reverseSortDirection}
                  onSort={() => setSorting("enabled")}
                >
                  {lang.status}
                </TableHeader>
              </Table.Tr>
            </Table.Thead>
            <Table.Tbody>
              {filtered.map((coupon) => (
                <Table.Tr
                  key={coupon.code}
                  style={{ cursor: "pointer" }}
                  onClick={() => setItem(coupon)}
                >
                  <Table.Td>
                    <Group wrap="nowrap" justify="space-between">
                      <Text fz="xs" c="var(--text-main)" maw={120} truncate>
                        {coupon.code}
                      </Text>
                      <ActionIcon
                        size="xs"
                        variant="transparent"
                        onClick={(e) => {
                          e.stopPropagation();
                          fetchNui("av_laptop", "copy", coupon.code);
                        }}
                      >
                        <IconCopy size={13} stroke={1.5} />
                      </ActionIcon>
                    </Group>
                  </Table.Td>
                  {wide && (
                    <Table.Td fz="xs" c="var(--text-dim)">
                      {coupon.description}
                    </Table.Td>
                  )}
                  <Table.Td
                    fz="sm"
                    c={
                      coupon.type == "amount" ? "var(--success)" : "var(--cyan)"
                    }
                    ff="var(--font-display)"
                  >
                    {coupon.type === "amount"
                      ? `$${coupon.discount}`
                      : `${coupon.discount}%`}
                  </Table.Td>
                  {wide && (
                    <Table.Td fz="xs" c="var(--text-dim)">
                      {coupon.employee}
                    </Table.Td>
                  )}
                  <Table.Td fz="sm" ff="var(--font-display)">
                    {`${coupon.redeemed.toLocaleString("en-US")}${coupon.limit ? ` / ${coupon.limit}` : ""}`}
                  </Table.Td>
                  <Table.Td>
                    <Badge
                      variant="light"
                      color={
                        coupon.enabled ? "var(--success)" : "var(--danger)"
                      }
                      size="sm"
                    >
                      {coupon.enabled ? lang.active : lang.inactive}
                    </Badge>
                  </Table.Td>
                </Table.Tr>
              ))}
            </Table.Tbody>
          </Table>
        </ScrollArea>
      </Stack>
    </>
  );
};

export default Discounts;
