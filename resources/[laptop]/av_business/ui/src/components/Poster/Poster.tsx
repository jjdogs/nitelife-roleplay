import "react-inner-image-zoom/lib/styles.min.css";
import { Box, Text } from "@mantine/core";
import InnerImageZoom from "react-inner-image-zoom";
import { useHover, useClickOutside } from "@mantine/hooks";
import { fetchNui } from "../../hooks/useNuiEvents";
import { useEffect } from "react";
import { useRecoilValue } from "recoil";
import { Lang } from "../../reducers/atoms";
import classes from "./style.module.css";

interface Properties {
  url: string;
}
export const Poster = ({ url }: Properties) => {
  const { hovered, ref } = useHover();
  const { poster: lang }: any = useRecoilValue(Lang);
  const clickRef = useClickOutside(() =>
    fetchNui("av_business", "closePoster")
  );
  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.code === "Escape") {
        fetchNui("av_business", "closePoster");
      }
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, []);

  return (
    <Box className={classes.container}>
      <Box className={classes.image} ref={ref} ta="center">
        {!hovered && <Text className={classes.text}>{lang.hover}</Text>}
        <div
          style={{
            filter: !hovered ? "blur(10px)" : "unset",
            overflow: "hidden",
          }}
          ref={clickRef}
        >
          <InnerImageZoom src={url} zoomSrc={url} hideCloseButton hideHint />
        </div>
      </Box>
    </Box>
  );
};
