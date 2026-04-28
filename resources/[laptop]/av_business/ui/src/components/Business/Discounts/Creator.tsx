import {
  Modal,
  Grid,
  Stack,
  TextInput,
  Text,
  ActionIcon,
  Button,
  Select,
  NumberInput,
} from "@mantine/core";
import { DatePickerInput } from "@mantine/dates";
import { useState } from "react";
import { ApiCoupon, DiscountType } from "./api";
import { IconWand } from "@tabler/icons-react";
import { generateCode, toTimestamp, useToday } from "./utils";
import global from "../../../global.module.css";
import { fetchNui } from "../../../hooks/useNuiEvents";
import { useRecoilValue } from "recoil";
import { Lang } from "../../../reducers/atoms";

export const Creator = ({
  handleCreator,
}: {
  handleCreator: (added: boolean) => void;
}) => {
  const daLang: any = useRecoilValue(Lang);
  const lang = daLang.discounts;
  const [coupon, setCoupon] = useState<DiscountType>(ApiCoupon);

  const updateField = (field: keyof DiscountType, value: any) => {
    setCoupon((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleSave = async () => {
    const resp = await fetchNui("av_business", "saveCoupon", coupon);
    if (!resp) return;
    handleCreator(true);
  };

  return (
    <Modal
      classNames={global}
      opened={true}
      onClose={() => {
        handleCreator(false);
      }}
      title={lang.modal_title}
      centered
      withinPortal
      lockScroll={false}
      trapFocus={false}
      styles={{
        title: { fontSize: "14px", fontWeight: 600 },
        content: { overflow: "hidden" },
      }}
    >
      <Grid>
        <Grid.Col span={6}>
          <Stack gap="xs">
            <TextInput
              withAsterisk
              classNames={global}
              size="xs"
              label={lang.code}
              placeholder={lang.code}
              value={coupon.code}
              onChange={(e) => {
                updateField("code", e.currentTarget.value.toUpperCase());
              }}
              rightSection={
                <ActionIcon
                  size="xs"
                  variant="transparent"
                  color="dimmed"
                  onClick={() => {
                    const code = generateCode();
                    updateField("code", code);
                  }}
                >
                  <IconWand style={{ height: 14, width: 14 }} stroke={1.5} />
                </ActionIcon>
              }
            />
            <NumberInput
              classNames={global}
              size="xs"
              label={lang.limit}
              min={0}
              max={100000}
              allowDecimal={false}
              allowLeadingZeros={false}
              allowNegative={false}
              w={200}
              onChange={(e) => {
                updateField("limit", e === 0 ? false : Number(e));
              }}
            />
            <Select
              classNames={global}
              withAsterisk
              size="xs"
              label={lang.type}
              data={[
                { value: "percentage", label: lang.percentage },
                { value: "amount", label: lang.amount },
              ]}
              value={coupon.type}
              allowDeselect={false}
              onChange={(e) => {
                updateField("type", e);
                updateField("discount", 1);
              }}
            />
          </Stack>
        </Grid.Col>
        <Grid.Col span={6}>
          <Stack gap="xs">
            <TextInput
              classNames={global}
              size="xs"
              label={lang.description}
              placeholder="My awesome discount"
              value={coupon.description}
              maxLength={50}
              onChange={(e) => {
                updateField("description", e.currentTarget.value);
              }}
            />
            <DatePickerInput
              classNames={global}
              size="xs"
              label={lang.expires}
              placeholder="Never"
              minDate={useToday()}
              clearable
              w={200}
              onChange={(e) => {
                if (!e) {
                  updateField("expires", false);
                  return;
                }
                const formated = toTimestamp(e);
                updateField("expires", formated);
              }}
            />
            <NumberInput
              classNames={global}
              withAsterisk
              size="xs"
              label={coupon.type === "amount" ? lang.amount : lang.percentage}
              min={1}
              max={coupon.type === "percentage" ? 100 : 1000000}
              clampBehavior="blur"
              value={coupon.discount}
              allowDecimal={false}
              allowNegative={false}
              leftSection={
                <Text c="dimmed" fz="xs">
                  {coupon.type === "percentage" ? "%" : "$"}
                </Text>
              }
              onChange={(val) => {
                const numValue = Number(val);
                if (isNaN(numValue) || numValue < 1) {
                  updateField("discount", 1);
                } else {
                  updateField("discount", numValue);
                }
              }}
            />
          </Stack>
        </Grid.Col>
      </Grid>
      <Button
        mt="sm"
        fullWidth
        className={global.button}
        size="xs"
        disabled={coupon.code.length === 0}
        onClick={handleSave}
      >
        {lang.generate_button}
      </Button>
    </Modal>
  );
};
