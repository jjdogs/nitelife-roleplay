import { useEffect, useState } from "react";
import {
  Group,
  Text,
  TextInput,
  Select,
  Button,
  ScrollArea,
  Table,
  Box,
  Flex,
} from "@mantine/core";
import {
  fetchNui,
  isEnvBrowser,
  useNuiEvent,
} from "../../../hooks/useNuiEvents";
import { TableHeader } from "../../TableHeader/TableHeader";
import { ApiBilling, ApiPremadeItems } from "../../../API/billing";
import { Loading } from "../../Loading";
import { useRecoilValue } from "recoil";
import { IconSearch } from "@tabler/icons-react";
import { Lang, MyPermissions } from "../../../reducers/atoms";
import { sortData } from "./helpers";
import { BillingType } from "../../../types/types";
import { Details } from "./Details";
import { Creator } from "./Creator";
import global from "../../../global.module.css";
import classes from "./style.module.css";

const Billing = ({ isLaptop }: { isLaptop?: boolean }) => {
  const daLang: any = useRecoilValue(Lang);
  const lang = daLang.billing;
  const permissions = useRecoilValue(MyPermissions);
  const [loaded, setLoaded] = useState(false);
  const [allBills, setAllBills] = useState<BillingType[]>([]);
  const [sortedData, setSortedData] = useState<BillingType[]>([]);
  const [items, setItems] = useState(ApiPremadeItems);
  const [search, setSearch] = useState("");
  const [sortBy, setSortBy] = useState<keyof BillingType | null>(null);
  const [reverseSortDirection, setReverseSortDirection] = useState(false);
  const [myIdentifier, setMyIdentifier] = useState("");
  const [showDetails, setShowDetails] = useState<BillingType | null>(null);
  const [showCreator, setShowCreator] = useState(false);
  const options = [
    { value: "paid", label: lang.paid },
    { value: "unpaid", label: lang.pending },
  ];
  useNuiEvent("bills", (data: BillingType[]) => {
    setAllBills(data);
    setSortedData(data);
  });
  const setSorting = (field: keyof BillingType) => {
    const reversed = field === sortBy ? !reverseSortDirection : false;
    setReverseSortDirection(reversed);
    setSortBy(field);
    setSortedData(sortData(allBills, { sortBy: field, reversed, search }));
  };

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const value = event.currentTarget.value;
    setSearch(value);
    setSortedData(
      sortData(allBills, {
        sortBy,
        reversed: reverseSortDirection,
        search: value,
      }),
    );
  };
  const handleFilter = (type: string | null) => {
    if (!type) {
      setSortedData(allBills);
    } else {
      const res = allBills.filter((bill) => {
        if (type === "paid") return bill.paid === true;
        if (type === "unpaid") return bill.paid === false;
        return true;
      });
      setSortedData(res);
    }
  };

  const handleDelete = async (identifier: string) => {
    setShowDetails(null);
    const resp = await fetchNui("av_business", "deleteInvoice", identifier);
    if (!resp) return;
    const updated = allBills.filter(
      (invoice) => invoice.invoiceid.trim() !== identifier,
    );
    setAllBills(updated);
    setSortedData(updated);
  };
  useEffect(() => {
    const fetchData = async () => {
      const resp = await fetchNui("av_business", "getBilling");
      if (resp) {
        setAllBills(resp.bills);
        setSortedData(resp.bills);
        setItems(resp.items);
        setMyIdentifier(resp.identifier);
      } else {
        if (isEnvBrowser()) {
          setAllBills(ApiBilling);
          setSortedData(ApiBilling);
        }
      }
      setTimeout(() => {
        setLoaded(true);
      }, 200);
    };
    fetchData();
    const onKeyDown = (e: KeyboardEvent) => {
      if (isLaptop) return;
      switch (e.code) {
        case "Escape":
          setLoaded(false);
          setTimeout(() => {
            fetchNui("av_business", "closeBillJob");
          }, 200);
          break;
        default:
          break;
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);
  if (!loaded) return <Loading />;

  const content = (
    <>
      {showCreator && (
        <Creator
          show={setShowCreator}
          items={items}
          daLang={daLang}
          isLaptop={isLaptop}
        />
      )}
      {showDetails && (
        <Details
          close={setShowDetails}
          data={showDetails}
          daLang={daLang}
          isLaptop={isLaptop}
          isBoss={permissions?.isBoss ? true : false}
          identifier={myIdentifier}
          handleDelete={handleDelete}
        />
      )}
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
            {`${allBills.length} ${lang.invoices}`}
          </Text>
        </Flex>
        <TextInput
          classNames={global}
          placeholder={lang.search}
          leftSection={<IconSearch size={16} stroke={1.5} />}
          value={search}
          onChange={handleSearchChange}
          size="xs"
          ml="auto"
          w={200}
        />
        <Select
          classNames={global}
          data={options}
          placeholder={lang.filter}
          size="xs"
          w={150}
          onChange={handleFilter}
        />
        <Button
          className={global.button}
          size="xs"
          variant="filled"
          onClick={() => {
            setShowCreator(true);
          }}
        >
          {lang.new_bill}
        </Button>
      </Group>
      <ScrollArea
        className={classes.scroll}
        type="hover"
        scrollbars={"y"}
        scrollbarSize={6}
        mt="sm"
        h={isLaptop ? undefined : 400}
      >
        <Table
          classNames={classes}
          horizontalSpacing="md"
          verticalSpacing="xs"
          stickyHeader
          layout="auto"
          highlightOnHover
        >
          <Table.Thead>
            <Table.Tr>
              <TableHeader
                sorted={sortBy === "customerName"}
                reversed={reverseSortDirection}
                onSort={() => setSorting("customerName")}
              >
                {lang.customer}
              </TableHeader>
              <TableHeader
                sorted={sortBy === "title"}
                reversed={reverseSortDirection}
                onSort={() => setSorting("title")}
              >
                {lang.title}
              </TableHeader>
              <TableHeader
                sorted={sortBy === "senderName"}
                reversed={reverseSortDirection}
                onSort={() => setSorting("senderName")}
              >
                {lang.employee}
              </TableHeader>

              <TableHeader
                sorted={sortBy === "amount"}
                reversed={reverseSortDirection}
                onSort={() => setSorting("amount")}
              >
                {lang.amount}
              </TableHeader>
              <TableHeader
                sorted={sortBy === "issued"}
                reversed={reverseSortDirection}
                onSort={() => setSorting("issued")}
              >
                {lang.issued}
              </TableHeader>
              <TableHeader
                sorted={sortBy === "paid"}
                reversed={reverseSortDirection}
                onSort={() => setSorting("paid")}
              >
                {lang.status}
              </TableHeader>
            </Table.Tr>
          </Table.Thead>
          <Table.Tbody>
            {sortedData.length > 0 &&
              sortedData.map((row) => (
                <Table.Tr
                  key={row.invoiceid}
                  style={{ cursor: "pointer" }}
                  onClick={() => {
                    setShowDetails(row);
                  }}
                >
                  <Table.Td>{row.customerName}</Table.Td>
                  <Table.Td>{row.title}</Table.Td>
                  <Table.Td>{row.senderName}</Table.Td>
                  <Table.Td
                    ff="var(--font-display)"
                    fz="md"
                    c="var(--success)"
                    lh={0}
                  >
                    {`${daLang.money_symbol}${row.amount.toLocaleString(
                      "en-US",
                    )}`}
                  </Table.Td>
                  <Table.Td c="var(--text-dim)">{row.issued}</Table.Td>
                  <Table.Td
                    c={row.paid ? `var(--success)` : `var(--yellow)`}
                    fz="xs"
                  >
                    {row.paid ? lang.paid : lang.pending}
                  </Table.Td>
                </Table.Tr>
              ))}
          </Table.Tbody>
        </Table>
      </ScrollArea>
    </>
  );
  if (isLaptop) return content;
  return (
    <Box className={classes.wrapper}>
      <Box className={classes.box} p="md">
        {content}
      </Box>
    </Box>
  );
};

export default Billing;
