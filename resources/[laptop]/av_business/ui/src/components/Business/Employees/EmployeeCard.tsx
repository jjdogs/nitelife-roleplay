import {
  Card,
  Group,
  Avatar,
  Flex,
  Text,
  Divider,
  ActionIcon,
} from "@mantine/core";
import { Employee } from "../../../types/types";
import { IconEdit, IconTrash } from "@tabler/icons-react";
import classes from "./style.module.css";

interface Properties {
  mainLang: any;
  employee: Employee;
  getGradeLabel: (gradeName: string | number) => string;
  handleEdit: (data: Employee) => void;
  fireEmployee: (data: Employee) => void;
}

export const EmployeeCard = ({
  mainLang,
  employee,
  getGradeLabel,
  fireEmployee,
  handleEdit,
}: Properties) => {
  return (
    <>
      <Card className={classes.employeeCard}>
        <Card.Section p="md">
          <Group>
            <Avatar src={employee.image} />
            <Flex direction="column">
              <Text c="var(--text-main)" fw={600}>
                {employee.name}
              </Text>
              <Text c="var(--text-dim)" fz="xs">
                {getGradeLabel(String(employee.grade.level))}
              </Text>
            </Flex>
          </Group>
        </Card.Section>
        <Card.Section>
          <Group
            justify="center"
            bg="var(--bg-main)"
            maw="65%"
            ml="auto"
            mr="auto"
            gap="xl"
            p="sm"
            style={{ borderRadius: "10px" }}
          >
            <Flex direction="column" ta="center">
              <Text fz="xs" c="var(--text-dim)">
                Tasks
              </Text>
              <Text ff="var(--font-display)">{employee.activities}</Text>
            </Flex>
            <Flex direction="column" ta="center">
              <Text fz="xs" c="var(--text-dim)">
                Hours
              </Text>
              <Text ff="var(--font-display)">{employee.hours}</Text>
            </Flex>
            <Flex direction="column" ta="center">
              <Text fz="xs" c="var(--text-dim)">
                Revenue
              </Text>
              <Text ff="var(--font-display)" c="var(--cyan)">
                {`${mainLang.money_symbol}${employee.generated.toLocaleString("en-US")}`}
              </Text>
            </Flex>
          </Group>
        </Card.Section>
        <Divider mt="sm" color="var(--border)" />
        <Card.Section p="md">
          <Group>
            <Text
              fz="xs"
              c="var(--text-dim)"
            >{`Last Seen: ${employee.lastSeen}`}</Text>
            <Group ml="auto" gap="xs">
              <ActionIcon
                size="xs"
                variant="transparent"
                color="var(--cyan)"
                onClick={() => {
                  handleEdit(employee);
                }}
              >
                <IconEdit />
              </ActionIcon>
              <ActionIcon
                size="xs"
                variant="transparent"
                color="var(--danger)"
                onClick={() => {
                  fireEmployee(employee);
                }}
              >
                <IconTrash />
              </ActionIcon>
            </Group>
          </Group>
        </Card.Section>
      </Card>
    </>
  );
};
