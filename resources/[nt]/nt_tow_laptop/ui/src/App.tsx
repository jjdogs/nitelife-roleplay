import { useEffect, useState } from "react";
import { MantineProvider, Box } from "@mantine/core";
import { isEnvBrowser } from "./hooks/useNuiEvents";
import { Lang } from "./reducers/atoms";
import { useSetRecoilState } from "recoil";
import { MainApp } from "./components/MainApp";
import { getLang } from "./hooks/getLang";
import "./App.css";
import "@mantine/core/styles.css";

const App = () => {
  const setLang = useSetRecoilState(Lang);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    const fetchLang = async () => {
      const resp = await getLang();
      setLang(resp);
      setLoaded(true);
    };
    fetchLang();
  }, []);
  return (
    <>
      {loaded && (
        <MantineProvider defaultColorScheme="dark">
          {isEnvBrowser() ? (
            <>
              <Box
                className="main-container"
                style={{
                  backgroundColor: isEnvBrowser() ? "black" : "transparent",
                }}
              >
                <Box
                  className="laptop-frame"
                  style={{
                    backgroundImage: `url(https://raw.githubusercontent.com/Renovamen/playground-macos/main/public/img/ui/wallpaper-night.jpg)`,
                    backgroundSize: "cover",
                  }}
                >
                  <Box className="app-window">
                    <MainApp />
                  </Box>
                </Box>
              </Box>
            </>
          ) : (
            <MainApp />
          )}
        </MantineProvider>
      )}
    </>
  );
};
export default App;
