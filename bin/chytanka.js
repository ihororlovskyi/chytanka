#!/usr/bin/env node
// Thin wrapper over install.sh, so npx and pnpm dlx install the same way as curl | sh.
import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";

const root = new URL("..", import.meta.url);
const { version } = JSON.parse(readFileSync(new URL("package.json", root), "utf8"));
const script = new URL("install.sh", root).pathname;

const command = process.argv[2] ?? "install";
const usage = `Usage: chytanka <install | update | uninstall>

  install     install Chytanka ${version} into /Applications
  update      install the latest release, if it is newer
  uninstall   remove the app, its settings, and the Accessibility grant`;

const args = { install: ["install", version], update: ["update"], uninstall: ["uninstall"] }[command];
if (!args) {
  console.log(usage);
  process.exit(command === "help" || command === "--help" || command === "-h" ? 0 : 1);
}
const result = spawnSync("/bin/sh", [script, ...args], { stdio: "inherit" });
process.exit(result.status ?? 1);
