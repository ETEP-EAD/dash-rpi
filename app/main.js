import { execFile } from "node:child_process";
import { promisify } from "node:util";
import path from "node:path";

const execFileAsync = promisify(execFile);

async function main() {
  try {
    const imagePath = path.resolve("/opt/dash-rpi/images/test.jpg");
    const renderCmd = "/usr/local/bin/render-image.sh";

    console.log("Dash-RPi test mode");
    console.log("Rendering image:", imagePath);

    await execFileAsync(renderCmd, [imagePath]);

    console.log("Image rendered successfully.");
  } catch (err) {
    console.error("Failed to render image:", err);
  }

  // mantém o processo vivo para o systemd
  setInterval(() => {}, 1000 * 60 * 60);
}

main();
