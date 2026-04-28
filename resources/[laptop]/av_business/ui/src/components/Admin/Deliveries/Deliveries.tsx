import { useEffect, useState } from "react";
import {
  Stack,
  Button,
  Group,
  Text,
  Grid,
  Switch,
  Card,
  NumberInput,
  MultiSelect,
  RangeSlider,
  Flex,
  Tooltip,
  Box,
} from "@mantine/core";
import { SelectType } from "../../../types/types";
import { fetchNui, isEnvBrowser } from "../../../hooks/useNuiEvents";
import { ApiDeliveries } from "../../../API/admin_settings";
import { DeliveriesType } from "../types";
import global from "../../../global.module.css";
import classes from "./style.module.css";
import { Loading } from "../../Loading";
import { MultiSelector } from "../MultiSelector";

const SettingCard = ({ title, tooltip, children, span = 3 }: any) => (
  <Grid.Col span={span}>
    <Card className={classes.card}>
      <Flex direction="column" gap="sm">
        <Group>
          <Text fz="sm" c="var(--text-dim)">
            {title}
          </Text>
          <Tooltip
            label={tooltip}
            fz="xs"
            color="var(--tooltip)"
            lts={1}
            multiline
            maw={220}
            withArrow
            position="top-start"
          >
            <Box className={classes.tooltip} bg="var(--tooltip)">
              <Text fz={10} c="var(--text-dim)">
                ?
              </Text>
            </Box>
          </Tooltip>
        </Group>
        {children}
      </Flex>
    </Card>
  </Grid.Col>
);

const Deliveries = ({ itemTypes }: { itemTypes: SelectType[] }) => {
  const [loaded, setLoaded] = useState(false);
  const [settings, setSettings] = useState<DeliveriesType>(ApiDeliveries);

  const updateField = <K extends keyof DeliveriesType>(
    field: K,
    value: DeliveriesType[K],
  ) => {
    setSettings((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleSave = () => {
    fetchNui("av_business", "updateSettings", { settings, type: "deliveries" });
  };
  useEffect(() => {
    const fetchData = async () => {
      const resp = await fetchNui("av_business", "getSettings", "deliveries");
      if (resp) {
        setSettings(resp);
      } else {
        if (isEnvBrowser()) {
          setSettings(ApiDeliveries);
        }
      }
      setTimeout(() => {
        setLoaded(true);
      }, 100);
    };
    fetchData();
  }, []);

  if (!loaded) return <Loading />;
  return (
    <Stack>
      <Group>
        <Text
          fz="xs"
          maw={400}
          style={{ wordBreak: "break-word" }}
          c="var(--text-dim)"
          lts={0.55}
        >
          Adjust the parameters for business deliveries. This system is linked
          to the 'Products' tab and requires appropriate job permissions.
        </Text>
        <Group ml="auto">
          <Switch
            checked={settings.enabled}
            classNames={global}
            color="var(--accent)"
            size="xs"
            label={settings.enabled ? "Enabled" : "Disabled"}
            onChange={(e) => {
              updateField("enabled", e.currentTarget.checked);
            }}
          />
          <Button className={global.button} size="xs" onClick={handleSave}>
            Save Changes
          </Button>
        </Group>
      </Group>
      <Grid>
        <SettingCard
          title={"Max Distance"}
          tooltip={"Delivery distance from business"}
        >
          <NumberInput
            classNames={global}
            size="xs"
            min={1}
            max={10000}
            value={settings.maxDistance}
            allowDecimal={false}
            onChange={(e) => {
              updateField("maxDistance", Number(e));
            }}
          />
        </SettingCard>
        <SettingCard
          title={"Min Products"}
          tooltip={"Min products the order can have"}
        >
          <NumberInput
            classNames={global}
            size="xs"
            min={1}
            max={50}
            value={settings.minProducts}
            allowDecimal={false}
            allowLeadingZeros={false}
            allowNegative={false}
            onChange={(e) => {
              updateField("minProducts", Number(e));
            }}
          />
        </SettingCard>
        <SettingCard
          title={"Max Products"}
          tooltip={"Max products the order can have"}
        >
          <NumberInput
            classNames={global}
            size="xs"
            min={1}
            max={1000}
            value={settings.maxProducts}
            allowDecimal={false}
            allowLeadingZeros={false}
            allowNegative={false}
            onChange={(e) => {
              updateField("maxProducts", Number(e));
            }}
          />
        </SettingCard>
        <SettingCard
          title={"Max Orders"}
          tooltip={"Max orders a business can hold at the same time"}
        >
          <NumberInput
            classNames={global}
            size="xs"
            min={1}
            max={100}
            value={settings.maxOrders}
            allowDecimal={false}
            allowLeadingZeros={false}
            allowNegative={false}
            onChange={(e) => {
              updateField("maxOrders", Number(e));
            }}
          />
        </SettingCard>
        <SettingCard
          title={"Max Price"}
          tooltip={
            "Maximum item price allowed. Items exceeding this value will be ignored"
          }
        >
          <NumberInput
            classNames={global}
            size="xs"
            min={1}
            max={1000000}
            value={settings.maxPrice}
            allowDecimal={false}
            allowLeadingZeros={false}
            allowNegative={false}
            onChange={(e) => {
              updateField("maxPrice", Number(e));
            }}
          />
        </SettingCard>
        <SettingCard
          title={"Max Tip"}
          tooltip={"Max tip a player can receive per order"}
        >
          <NumberInput
            classNames={global}
            size="xs"
            min={1}
            max={1000000}
            value={settings.maxTip}
            allowDecimal={false}
            allowLeadingZeros={false}
            allowNegative={false}
            onChange={(e) => {
              updateField("maxTip", Number(e));
            }}
          />
        </SettingCard>
        <SettingCard
          title={"Item Overprice"}
          tooltip={"% added to base item price to ensure profit"}
        >
          <NumberInput
            classNames={global}
            size="xs"
            min={1}
            max={100}
            value={settings.overprice}
            allowDecimal={false}
            allowLeadingZeros={false}
            allowNegative={false}
            onChange={(e) => {
              updateField("overprice", Number(e));
            }}
          />
        </SettingCard>
        <SettingCard
          title={"Ignored Item Types"}
          tooltip={"Item types that will be excluded from deliveries"}
        >
          <MultiSelector
            values={settings.toIgnore}
            data={itemTypes}
            updateData={(e) => {
              updateField("toIgnore", e);
            }}
          />
        </SettingCard>
        <SettingCard
          title={"Waiting Time"}
          tooltip={
            "Randomized wait time (between min and max) until the next delivery becomes available"
          }
        >
          <RangeSlider
            mt="xs"
            classNames={global}
            size="xs"
            value={[
              settings.deliveryWait[0] ?? 1,
              settings.deliveryWait[1] ?? 30,
            ]}
            min={1}
            max={30}
            step={1}
            minRange={1}
            onChange={(e) => {
              updateField("deliveryWait", e);
            }}
          />
        </SettingCard>
      </Grid>
    </Stack>
  );
};

export default Deliveries;
