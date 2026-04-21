import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// https://vitejs.dev/config/
export default defineConfig(({ command }) => ({
  // 1. CAMBIO IMPORTANTE: FiveM necesita rutas relativas "./"
  // "/ui/dist" busca en la raíz del servidor, lo cual rompe los assets en el juego.
  base: "./",

  define: {
    global: "window",
  },

  build: {
    sourcemap: false,
    // La carpeta de salida estándar suele ser 'dist' o 'build' dentro de 'ui'
    outDir: "dist",
    emptyOutDir: true,
    rollupOptions: {
      // 2. CAMBIO IMPORTANTE: Asegúrate de que esto esté vacío
      external: [],
    },
  },

  optimizeDeps: {
    esbuildOptions: {
      mainFields: ["module", "main"],
      // 3. CAMBIO CRÍTICO: Mantine usa archivos .mjs
      // Tu config anterior solo leía .js y .jsx, ignorando los archivos de Mantine
      resolveExtensions: [".js", ".jsx", ".ts", ".tsx", ".mjs"],
    },
  },

  server: {
    port: 3000,
    open: true,
  },

  plugins: [react()],
}));
