import {
  Grid,
  Text,
  Card,
  TextInput,
  Group,
  Stack,
  Button,
  Image,
} from "@mantine/core";
import { useRecoilValue } from "recoil";
import { Lang } from "../../../reducers/atoms";
import { fetchNui } from "../../../hooks/useNuiEvents";
import { useViewportSize } from "@mantine/hooks";
import { useEffect, useState } from "react";
import { Loading } from "../../Loading";
import classes from "./style.module.css";
import global from "../../../global.module.css";

const Poster = () => {
  const daLang: any = useRecoilValue(Lang);
  const lang = daLang.poster;
  const [loaded, setLoaded] = useState(false);
  const [poster, setPoster] = useState("");
  const { height } = useViewportSize();

  useEffect(() => {
    const fetchData = async () => {
      const resp = await fetchNui("av_business", "getPoster");
      if (resp) {
        setPoster(resp);
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
      <Group
        bg="var(--bg-card)"
        p="sm"
        style={{
          borderRadius: "6px",
          border: "solid 1px rgba(255,255,255,0.1)",
        }}
      >
        <Text fz="lg" c="var(--text-main)" fw={500} lts={1}>
          {lang.header}
        </Text>
      </Group>
      <Grid mt="md">
        <Grid.Col span={"auto"} maw={height > 700 ? "51vh" : "41vh"}>
          <Image
            src={poster}
            fallbackSrc="./poster_default.png"
            w={height > 700 ? "50vh" : "40vh"}
            style={{ border: "solid 1px rgba(255,255,255,0.11)" }}
          />
        </Grid.Col>
        <Grid.Col maw={height > 700 ? 500 : 350}>
          <Card className={classes.card}>
            <Stack>
              <Stack gap="xs">
                <Text c="var(--text-main)" fz={height > 700 ? "md" : "sm"}>
                  {lang.description}
                </Text>
                <Text c="var(--text-dim)" fz="xs">
                  {lang.dimensions}
                </Text>
                <Text c="var(--text-dim)" fz="xs">
                  {lang.hosts}
                </Text>
              </Stack>
              <TextInput
                classNames={global}
                placeholder={lang.url}
                value={poster ?? undefined}
                size="xs"
                onChange={(e) => {
                  setPoster(e.currentTarget.value);
                }}
              />
              <Button
                className={global.button}
                size="xs"
                variant="filled"
                onClick={() => {
                  fetchNui("av_business", "updatePoster", poster);
                }}
              >
                {lang.save}
              </Button>
            </Stack>
          </Card>
        </Grid.Col>
      </Grid>
    </>
  );
};
export default Poster;
