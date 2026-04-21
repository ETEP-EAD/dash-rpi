import fs from "fs";

export function getSerialNumber() {
  try {
    const cpuinfo = fs.readFileSync("/proc/cpuinfo", "utf8");

    const match = cpuinfo
      .split("\n")
      .find(line => line.startsWith("Serial"));

    if (!match) {
      throw new Error("Serial not found in /proc/cpuinfo");
    }

    const serial = match.split(":")[1].trim();

    // fallback safety check
    if (!serial || serial === "0000000000000000") {
      throw new Error("Invalid CPU serial detected");
    }

    return serial;
  } catch (err) {
    throw new Error(`Failed to get Raspberry Pi serial: ${err.message}`);
  }
}
