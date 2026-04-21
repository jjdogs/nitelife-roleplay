import { useEffect, useState, useCallback } from "react";
import {
  ScrollArea,
  Flex,
  Stack,
  Box,
  Text,
  Badge,
  Button,
  Group,
  Transition,
  Divider,
} from "@mantine/core";
import { Power, LogOut } from "lucide-react";
import { JobsType } from "../types/types";
import { fetchNui, isEnvBrowser, useNuiEvent } from "../hooks/useNuiEvents";
import { ApiJobs } from "../Api/Jobs";
import { useAtomValue } from "jotai";
import { Lang } from "../reducers/atoms";
import { Loading } from "./Loading";
import classes from "./style.module.css";

export const sortJobs = (jobs: JobsType[]) => {
  return [...jobs].sort((a, b) => {
    if (a.active !== b.active) {
      return a.active ? -1 : 1;
    }
    return a.label.localeCompare(b.label);
  });
};

export const MultiJobManager = () => {
  const lang: any = useAtomValue(Lang);
  const [loading, setLoading] = useState(true);
  const [jobs, setJobs] = useState<JobsType[]>([]);
  const [visible, setVisible] = useState(isEnvBrowser());
  const [max, setMax] = useState(5);

  const handleDuty = async (job: string) => {
    const resp = await fetchNui("av_multijob", "toggleDuty", job);
    if (resp) {
      setJobs((prevJobs) => {
        const updatedJobs = prevJobs.map((j) => ({
          ...j,
          active: j.name === resp.name,
          onDuty: j.name === resp.name ? resp.duty : false,
        }));
        return sortJobs(updatedJobs);
      });
    }
  };

  const handleQuit = (job: string) => {
    fetchNui("av_multijob", "quitJob", job);
  };

  const fetchData = useCallback(async () => {
    if (jobs.length === 0) {
      setLoading(true);
    }

    const resp = await fetchNui("av_multijob", "getData");
    if (resp) {
      const sortedJobs = sortJobs(resp.jobs);
      setJobs(sortedJobs);
      setMax(resp.max);
    } else if (isEnvBrowser()) {
      setJobs(ApiJobs);
    }
    setLoading(false);
  }, [jobs.length]);

  useNuiEvent("refresh", () => {
    if (!visible) return;
    fetchData();
  });

  useEffect(() => {
    if (isEnvBrowser()) {
      fetchData();
    }

    const handleNuiMessage = (event: MessageEvent) => {
      const data = event.data;
      switch (data.message) {
        case "open":
          if (data.state) {
            setVisible(true);
            setTimeout(() => {
              fetchData();
            }, 300);
          } else {
            setVisible(false);
            setTimeout(() => setJobs([]), 300);
          }
          break;
        default:
          break;
      }
    };

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.code === "Escape" || e.code === "Backspace") {
        setVisible(false);
        setTimeout(() => {
          fetchNui("av_multijob", "close");
        }, 100);
      }
    };

    window.addEventListener("message", handleNuiMessage);
    window.addEventListener("keydown", onKeyDown);

    return () => {
      window.removeEventListener("message", handleNuiMessage);
      window.removeEventListener("keydown", onKeyDown);
    };
  }, [fetchData]);

  return (
    <Transition
      mounted={visible}
      transition="fade"
      duration={250}
      exitDuration={250}
    >
      {(styles) => (
        <Stack className={classes.container} gap="sm" style={styles}>
          <Text
            ff="var(--font-display)"
            fz="xl"
            fw={700}
            c="var(--accent)"
            tt="uppercase"
            lts={3}
          >
            {lang.header}
          </Text>
          <Divider color="var(--border)" size="sm" />
          <Box flex={1}>
            {loading ? (
              <Loading />
            ) : jobs.length > 0 ? (
              <ScrollArea.Autosize mah={500} scrollbarSize={5} offsetScrollbars>
                <Stack gap="xs">
                  {jobs.map((job) => (
                    <Box
                      key={job.name}
                      className={classes.jobCard}
                      style={{
                        borderLeft: job.onDuty
                          ? `4px solid var(--color-green)`
                          : job.active
                            ? `4px solid var(--color-red)`
                            : undefined,
                      }}
                    >
                      <Group>
                        <Flex direction="column" ff="var(--font-display)">
                          <Text
                            fz="lg"
                            tt="uppercase"
                            c="var(--text-main)"
                            fw={700}
                          >
                            {job.label}
                          </Text>
                          <Text fz="sm" tt="uppercase" c="var(--text-dim)">
                            {job.gradeLabel}
                          </Text>
                        </Flex>
                        <Badge
                          className={classes.badge}
                          c={job.restricted ? "var(--color-red)" : ""}
                          bg={
                            job.restricted
                              ? "transparent"
                              : job.onDuty
                                ? "transparent"
                                : "var(--bg-badge)"
                          }
                          ml="auto"
                        >
                          {job.restricted
                            ? lang.restricted
                            : job.onDuty
                              ? lang.on_duty
                              : lang.off_duty}
                        </Badge>
                      </Group>
                      <Group mt="xs" grow>
                        <Button
                          disabled={job.restricted}
                          color={
                            job.onDuty ? "var(--color-green)" : "var(--accent)"
                          }
                          variant="outline"
                          size="xs"
                          leftSection={<Power size={12} />}
                          onClick={() => {
                            handleDuty(job.name);
                          }}
                        >
                          {job.onDuty ? lang.clock_out : lang.clock_in}
                        </Button>
                        <Button
                          disabled={job.restricted}
                          color="var(--color-red)"
                          variant="outline"
                          size="xs"
                          leftSection={<LogOut size={12} />}
                          onDoubleClick={() => {
                            handleQuit(job.name);
                          }}
                        >
                          {lang.quit_job}
                        </Button>
                      </Group>
                    </Box>
                  ))}
                </Stack>
              </ScrollArea.Autosize>
            ) : (
              <Flex
                justify="center"
                align="center"
                h={300}
                w="100%"
                ta="center"
              >
                <Text fz="sm" c="var(--text-dim)">
                  {lang.unemployed}
                </Text>
              </Flex>
            )}
          </Box>
          <Divider color="var(--border)" size="xs" />
          <Group>
            <Text fz="xs" c="var(--text-dim)" lts={0.25}>
              {lang.max}: <b>{max}</b>
            </Text>
            <Text fz="xs" c="var(--text-dim)" ml="auto" lts={0.25}>
              <b>{lang.key}</b>
              {` ${lang.exit}`}
            </Text>
          </Group>
        </Stack>
      )}
    </Transition>
  );
};
