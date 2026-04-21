import { io } from "socket.io-client";

import { getSerialNumber } from "./utils.js";
import { renderImageToFramebuffer } from "./fb-renderer.js";

const DEVICE_ID = getSerialNumber();

export function initSocket() {
  const socket = io("http://192.168.2.144:3000", {
    transports: ["websocket"], // força websocket (melhor pro embedded)
    reconnection: true,
    reconnectionAttempts: Infinity,
    reconnectionDelay: 2000
  });

  socket.on("connect", () => {
    console.log("🔌 Conectado ao backend");

    // handshake manual com deviceId
    socket.emit("register_device", {
      deviceId: DEVICE_ID,
      platform: "raspberry-pi"
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

  return socket;
}
