import { useEffect, useState } from "react";
import {
  ScrollArea,
  Text,
  TextInput,
  Group,
  Button,
  Grid,
  Flex,
  Select,
} from "@mantine/core";
import { IconSearch } from "@tabler/icons-react";
import { ApiEmployees } from "../../../API/employees";
import { Employee, ModalType } from "../../../types/types";
import { fetchNui, isEnvBrowser } from "../../../hooks/useNuiEvents";
import { useRecoilValue } from "recoil";
import { ModalMenu } from "../../ModalMenu/ModalMenu";
import { BusinessInfo, Lang } from "../../../reducers/atoms";
import { Loading } from "../../Loading";
import { EmployeeCard } from "./EmployeeCard";
import { sortEmployeesAlphabetically } from "./utils";
import { formatString } from "../../../hooks/formatString";
import classes from "./style.module.css";
import global from "../../../global.module.css";

const keysToExclude = ["owner", "isBoss"];

type Grade = {
  value: string;
  label: string;
};

const Employees = () => {
  const mainLang: any = useRecoilValue(Lang);
  const lang = mainLang.employees;
  const [loaded, setLoaded] = useState(false);
  const { name } = useRecoilValue(BusinessInfo);
  const [allEmployees, setAllEmployees] = useState<Employee[]>([]);
  const [allGrades, setAllGrades] = useState<Grade[]>([]);
  const [allPermissions, setAllPermissions] = useState([]);
  const [sortedData, setSortedData] = useState<Employee[]>([]);
  const [modal, setModal] = useState<ModalType>({
    state: false,
    info: {
      title: "",
      options: [],
    },
  });
  const sortOptions = [
    { value: "grade", label: lang.grade },
    { value: "hours", label: lang.hours },
    { value: "activities", label: lang.activities },
    { value: "generated", label: lang.monthlyGenerated },
  ];

  const handleSortChange = (value: string | null) => {
    if (!value) {
      setSortedData(allEmployees);
    }

    const sorted = [...allEmployees].sort((a, b) => {
      switch (value) {
        case "hours":
          return b.hours - a.hours;
        case "activities":
          return b.activities - a.activities;
        case "generated":
          return b.generated - a.generated;
        case "grade":
          return b.grade.level - a.grade.level;
        default:
          return 0;
      }
    });
    setSortedData(sorted);
  };
  function getGradeLabel(gradeName: string | number): string {
    const gradesArray = Array.isArray(allGrades) ? allGrades : [allGrades];
    const match = gradesArray.find((grade) => grade.value === gradeName);
    return match ? match.label : "N/A";
  }

  const handleEdit = (employee: any) => {
    const identifier = employee.identifier;
    const permissions = { ...employee.permissions };
    const currentPermissions: string[] = Object.keys(permissions).filter(
      (key) => {
        return permissions[key] === true && !keysToExclude.includes(key);
      },
    );
    setModal({
      ...modal,
      state: true,
      info: {
        title: employee.name,
        options: [
          {
            type: "image",
            image: employee.image,
            height: 100,
            title: employee.name,
            style: { marginTop: "10px" },
            default: "./user_default.png",
          },
          {
            name: "photo",
            title: lang.photo,
            type: "text",
            default: employee.image,
          },
          {
            name: "grade",
            title: lang.grade,
            type: "select",
            default: String(employee.grade.level),
            options: allGrades,
          },
          {
            name: "permissions",
            title: lang.permissions,
            type: "multiselect",
            default: currentPermissions,
            options: allPermissions,
          },
        ],
        extraData: { event: "updateEmployee", identifier, name },
        button: lang.confirm,
      },
    });
  };
  const modalCallback = async (data?: any) => {
    setModal({ ...modal, state: false });
    if (!data) {
      return;
    }
    if (data?.extraData) {
      const { event } = data.extraData;
      const resp = await fetchNui("av_business", event, data);
      if (resp) {
        const sorted = sortEmployeesAlphabetically(resp);
        setAllEmployees(sorted);
        setSortedData(sorted);
      }
    }
  };

  const handleSearchChange = (input: string) => {
    const res = allEmployees.filter((employee) =>
      employee.name ? employee.name.toLowerCase().includes(input) : false,
    );
    setSortedData(res);
  };

  const fireEmployee = (employee: any) => {
    const identifier = employee.identifier;
    setModal({
      ...modal,
      state: true,
      info: {
        title: `${employee.name}`,
        options: [
          {
            type: "info",
            description: lang.fireText,
            size: "sm",
          },
        ],
        button: lang.confirm,
        extraData: { event: "fireEmployee", identifier, name },
      },
    });
  };

  const handleHire = async () => {
    setLoaded(false);
    const resp = await fetchNui("av_business", "hireEmployee");
    if (resp) {
      setAllEmployees(resp);
      setSortedData(resp);
    }
    setLoaded(true);
  };
  useEffect(() => {
    const fetchData = async () => {
      const resp = await fetchNui("av_business", "getEmployees");
      if (resp) {
        const sorted = sortEmployeesAlphabetically(resp.employees);
        setAllEmployees(sorted);
        setSortedData(sorted);
        setAllGrades(resp.grades);
        setAllPermissions(resp.allPermissions);
      } else {
        if (isEnvBrowser()) {
          const sorted = sortEmployeesAlphabetically(ApiEmployees);
          setAllEmployees(sorted);
          setSortedData(sorted);
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
      {modal.state && (
        <div
          style={{
            position: "relative",
            backgroundColor: "red",
            overflow: "hidden",
          }}
        >
          <ModalMenu data={modal} callback={modalCallback} />
        </div>
      )}
      <Group
        bg="var(--bg-card)"
        p="sm"
        style={{
          borderRadius: "6px",
          border: "solid 1px rgba(255,255,255,0.1)",
        }}
      >
        <Flex gap="xs" direction="column">
          <Text ff="var(--font-display)" tt="uppercase" fz="xl" fw={700}>
            {lang.header}
          </Text>
          <Text mt={-15} fz="xs" c="var(--text-dim)">
            {formatString(lang.employees, String(sortedData.length))}
          </Text>
        </Flex>
        <Group ml="auto" gap="xs">
          <Select
            classNames={global}
            placeholder="Sort by"
            size="xs"
            w={155}
            data={sortOptions}
            onChange={(e) => {
              handleSortChange(e);
            }}
          />
          <TextInput
            classNames={global}
            placeholder={lang.search}
            leftSection={<IconSearch size={16} stroke={1.5} />}
            onChange={(e) => {
              handleSearchChange(e.currentTarget.value);
            }}
            size="xs"
            w={170}
          />
          <Button
            className={global.button}
            size="xs"
            onClick={handleHire}
            variant="filled"
          >
            {lang.hire}
          </Button>
        </Group>
      </Group>
      <ScrollArea
        type="hover"
        scrollbars={"y"}
        scrollbarSize={6}
        className={classes.scroll}
        mt="sm"
      >
        <Grid grow={sortedData.length > 3}>
          {sortedData.map((employee) => (
            <Grid.Col span={4} miw={355}>
              <EmployeeCard
                employee={employee}
                getGradeLabel={getGradeLabel}
                mainLang={mainLang}
                handleEdit={handleEdit}
                fireEmployee={fireEmployee}
              />
            </Grid.Col>
          ))}
        </Grid>
      </ScrollArea>
    </>
  );
};

export default Employees;
