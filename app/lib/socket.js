import { io } from "socket.io-client";
import fs from "fs";

import { getSerialNumber } from "./utils.js";
import { getFbInfo, renderImageToFramebuffer, renderBufferToFramebuffer } from "./fb-renderer.js";

const DEVICE_ID = getSerialNumber();
const BACKEND_WS_URL = process.env.BACKEND_WS_URL || "https://dash.4growth.co";

export function initSocket() {
  const socket = io(BACKEND_WS_URL, {
    transports: ["websocket"], // força websocket (melhor pro embedded)
    reconnection: true,
    reconnectionAttempts: Infinity,
    reconnectionDelay: 2000
  });

  socket.on("connect", () => {
    console.log("🔌 Conectado ao backend");
    const { width, height, bpp, stride } = getFbInfo();

    // handshake manual com deviceId
    socket.emit("register_device", {
      deviceId: DEVICE_ID,
      platform: "raspberry-pi",
      screen: { width, height, bpp, stride }
    });
  });

  socket.on("disconnect", () => {
    console.log("❌ Desconectado do backend");
  });

  socket.on("connect_error", (err) => {
    console.log("⚠️ Erro de conexão:", err.message);
  });

  socket.on("show", (data) => {
    console.log("🖼️ imagem recebida");

    const buffer = Buffer.from(data.image, "base64");

    const filePath = "/tmp/screen.png";

    fs.writeFileSync(filePath, buffer);

    // 👇 aqui depende do seu setup de display
    renderImageToFramebuffer(filePath);
  });

  socket.on("show_buffer", async (data) => {
    console.log("🖼️ buffer recebido");

    const buffer = data.image;

    await renderBufferToFramebuffer(buffer);
  });

  return socket;
}
