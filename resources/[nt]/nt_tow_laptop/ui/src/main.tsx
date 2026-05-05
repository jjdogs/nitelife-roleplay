import "@mantine/core/styles.css";
import React from "react";
import ReactDOM from "react-dom/client";
import { isEnvBrowser } from "./hooks/useNuiEvents.ts";
import { RecoilRoot } from "recoil";
import App from "./App.tsx";
import "./index.css";
import "./global.css";

let root: ReactDOM.Root | null = null;

const initializeRoot = () => {
  root = ReactDOM.createRoot(document.getElementById("root")!);
};

const loadApp = () => {
  if (!root) initializeRoot();
  root?.render(
    <React.StrictMode>
      <RecoilRoot>
        <App />
      </RecoilRoot>
    </React.StrictMode>
  );
};

window.addEventListener("message", (event) => {
  switch (event.data.message) {
    case "loadApp":
      loadApp();
      break;
    case "close":
      if (root) {
        root.unmount();
        root = null;
      }
      break;
    default:
      break;
  }
});

if (isEnvBrowser()) loadApp(); // load main app
