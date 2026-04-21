import { useEffect, useState } from "react";
import { MantineProvider } from "@mantine/core";
import { useSetAtom } from "jotai";
import { Lang } from "./reducers/atoms";
import { getLang } from "./hooks/getLang";
import { MultiJobManager } from "./components/Panel";

const App = () => {
  const setLang = useSetAtom(Lang);
  const [loaded, setLoaded] = useState(false);

  const fetchInit = async () => {
    try {
      const response = await getLang();
      setLang(response);
      setLoaded(true);
    } catch (error) {
      console.error("Error loading init data:", error);
    }
  };

  useEffect(() => {
    if (!loaded) {
      fetchInit();
    }
  }, []);

  return (
    <MantineProvider defaultColorScheme="dark">
      <MultiJobManager />
    </MantineProvider>
  );
};

export default App;
