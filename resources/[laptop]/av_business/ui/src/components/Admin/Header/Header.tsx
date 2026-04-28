import { Group, Text, Button, Menu, ActionIcon } from "@mantine/core";
import { IconDotsVertical } from "@tabler/icons-react";
import classes from "../style.module.css";
import global from "../../../global.module.css";

interface Properties {
  tab: string;
  setTab: (option: string) => void;
}

export const Header = ({ tab, setTab }: Properties) => {
  const tabs = [
    { value: "home", label: "Home" },
    { value: "animations", label: "Animations" },
    { value: "crafting", label: "Crafting" },
    { value: "deliveries", label: "Deliveries" },
    { value: "ingredients", label: "Ingredients" },
    { value: "items", label: "Items" },
    { value: "permissions", label: "Permissions" },
    { value: "logs", label: "Logs" },
  ];
  return (
    <Group className={classes.header} p="sm">
      <Group gap="xs">
        <Text fw={500} lts={1.25} c="var(--text-main)">
          AV Business
        </Text>
        <Text fz="xs" c="var(--text-dim)">
          Admin Panel
        </Text>
      </Group>
      <Group ml="auto" gap={1}>
        {tabs.slice(0, 4).map((option) => (
          <Button
            className={option.value == tab ? classes.active : classes.disabled}
            fz="md"
            fw={400}
            ff="var(--font-display)"
            lts={1}
            key={option.value}
            variant="transparent"
            size="xs"
            onClick={() => {
              setTab(option.value);
            }}
          >
            {option.label}
          </Button>
        ))}
        <Menu
          shadow="md"
          width={145}
          classNames={global}
          zIndex={9999}
          withinPortal={false}
        >
          <Menu.Target>
            <ActionIcon className={classes.disabled}>
              <IconDotsVertical style={{ height: "14px", width: "14px" }} />
            </ActionIcon>
          </Menu.Target>
          <Menu.Dropdown>
            {tabs.slice(4).map((t) => (
              <Menu.Item
                ta="center"
                key={t.value}
                className={t.value == tab ? classes.active : classes.disabled}
                onClick={() => setTab(t.value)}
                fz="sm"
                fw={400}
              >
                {t.label}
              </Menu.Item>
            ))}
          </Menu.Dropdown>
        </Menu>
      </Group>
    </Group>
  );
};
