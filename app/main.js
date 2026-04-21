import { renderImageToFramebuffer } from "./lib/fb-renderer.js";
import { initSocket } from "./lib/socket.js";

async function main() {
  const imagePath = "/opt/dash-rpi/images/test.jpg";

  try {
    await renderImageToFramebuffer(imagePath);
  } catch (err) {
    console.error(err);
  }

  const socket = initSocket();

  // mantém processo vivo (systemd)
  setInterval(() => {}, 1000 * 60 * 60);
}

main();
