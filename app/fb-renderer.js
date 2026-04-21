import fs from "node:fs";
import sharp from "sharp";
import { execSync } from "node:child_process";

const FB_PATH = "/dev/fb0";

function getFbInfo() {
  const output = execSync("fbset -s").toString();

  const match = output.match(/geometry\s+(\d+)\s+(\d+)\s+\d+\s+\d+\s+(\d+)/);

  if (!match) throw new Error("Erro lendo framebuffer");

  const width = parseInt(match[1], 10);
  const height = parseInt(match[2], 10);
  const bpp = parseInt(match[3], 10);

  const stride = parseInt(
    fs.readFileSync("/sys/class/graphics/fb0/stride", "utf-8").trim(),
    10
  );

  return { width, height, bpp, stride };
}

function rgbaToRgb565(buffer) {
  const out = Buffer.alloc((buffer.length / 4) * 2);

  for (let i = 0, j = 0; i < buffer.length; i += 4, j += 2) {
    const r = buffer[i];
    const g = buffer[i + 1];
    const b = buffer[i + 2];

    const value =
      ((r >> 3) << 11) |
      ((g >> 2) << 5)  |
      (b >> 3);

    out[j] = value & 0xff;
    out[j + 1] = value >> 8;
  }

  return out;
}

async function renderImageToFramebuffer(imagePath) {
  const { width, height, bpp, stride } = getFbInfo();

  console.log(`Framebuffer: ${width}x${height} (${bpp}bpp)`);

  const rgba = await sharp(imagePath)
    .resize(width, height, { fit: "cover" })
    .ensureAlpha()
    .raw()
    .toBuffer();

  let finalBuffer;

  if (bpp === 16) {
    console.log("Convertendo para RGB565...");
    finalBuffer = rgbaToRgb565(rgba);
  } else if (bpp === 32) {
    console.log("Usando RGBA direto...");
    finalBuffer = rgba;
  } else {
    throw new Error(`Formato não suportado: ${bpp} bpp`);
  }

  const bytesPerPixel = bpp / 8;

  const fb = fs.openSync(FB_PATH, "w");

  for (let y = 0; y < height; y++) {
    const srcStart = y * width * bytesPerPixel;
    const srcEnd = srcStart + width * bytesPerPixel;

    const line = finalBuffer.subarray(srcStart, srcEnd);

    fs.writeSync(fb, line, 0, line.length, y * stride);
  }

  fs.closeSync(fb);
}

export { renderImageToFramebuffer };
