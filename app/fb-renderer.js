import fs from "node:fs";
import sharp from "sharp";
import { execSync } from "node:child_process";

const FB_PATH = "/dev/fb0";

function getFbInfo() {
  const output = execSync("fbset -fb /dev/fb0 -s").toString();

  const geo = output.match(/geometry\s+(\d+)\s+(\d+)\s+\d+\s+\d+\s+(\d+)/);
  const line = output.match(/rgba\s+\d+\/\d+,\d+\/\d+,\d+\/\d+,\d+\/\d+/);

  if (!geo) throw new Error("Erro lendo framebuffer");

  const width = parseInt(geo[1], 10);
  const height = parseInt(geo[2], 10);
  const bpp = parseInt(geo[3], 10);

  const bytesPerPixel = bpp / 8;

  // pegar stride via fbset não é confiável → calcular depois
  const stride = width * bytesPerPixel;

  return { width, height, bytesPerPixel, stride };
}

export async function renderImageToFramebuffer(imagePath) {
  const { width, height, bytesPerPixel, stride } = getFbInfo();

  console.log({ width, height, bytesPerPixel, stride });

  const raw = await sharp(imagePath)
    .resize(width, height, { fit: "cover" })
    .raw()
    .toBuffer();

  const fb = fs.openSync(FB_PATH, "w");

  for (let y = 0; y < height; y++) {
    const srcStart = y * width * bytesPerPixel;
    const srcEnd = srcStart + width * bytesPerPixel;

    const line = raw.subarray(srcStart, srcEnd);

    fs.writeSync(fb, line, 0, line.length, y * stride);
  }

  fs.closeSync(fb);

  console.log("Render OK");
}
