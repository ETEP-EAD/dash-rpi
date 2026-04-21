import fs from "node:fs";
import sharp from "sharp";
import { execSync } from "node:child_process";

const FB_PATH = "/dev/fb0";

function getFramebufferInfo() {
  const output = execSync("fbset -s").toString();

  const match = output.match(/geometry\s+(\d+)\s+(\d+)/);

  if (!match) {
    throw new Error("Não foi possível detectar resolução do framebuffer");
  }

  return {
    width: parseInt(match[1], 10),
    height: parseInt(match[2], 10),
  };
}

async function renderImageToFramebuffer(imagePath) {
  const { width, height } = getFramebufferInfo();

  console.log(`Framebuffer: ${width}x${height}`);

  // converte imagem para RGBA raw no tamanho da tela
  const buffer = await sharp(imagePath)
    .resize(width, height, { fit: "cover" })
    .raw()
    .toBuffer();

  // escreve direto no framebuffer
  const fb = fs.openSync(FB_PATH, "w");

  fs.writeSync(fb, buffer, 0, buffer.length, 0);

  fs.closeSync(fb);

  console.log("Imagem renderizada no framebuffer.");
}

export { renderImageToFramebuffer };
