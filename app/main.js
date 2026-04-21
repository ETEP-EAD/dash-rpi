import { renderImageToFramebuffer } from "./fb-renderer.js";

async function main() {
  const imagePath = "/opt/dash-rpi/images/test.jpg";

  try {
    await renderImageToFramebuffer(imagePath);
  } catch (err) {
    console.error(err);
  }

  // mantém processo vivo (systemd)
  setInterval(() => {}, 1000 * 60 * 60);
}

main();
