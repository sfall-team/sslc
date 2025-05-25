#!/usr/bin/env node

// TODO: Make this as "bin" in the package

import path from "path";
import Module from "./sslc.mjs";
import http from "http";
import fs from "fs";

async function mainWithDaemon() {
  const daemonPidFile = "/tmp/sslc-daemon.pid";
  const port = 48293;

  const arg = process.env.DAEMON;

  if (!arg) {
    return false;
  }
  // const cmdArg = process.argv[2] || "";

  if (arg === "start") {
    fs.writeFileSync(daemonPidFile, process.pid.toString());

    http
      .createServer((req, res) => {
        console.info("Incoming request: " + req.url);
        const args = JSON.parse(decodeURIComponent(req.url.slice(1)));
        console.info("  Args:", args);
        compile(args).then(({ stdout, stderr, returnCode }) => {
          res.writeHead(200, { "Content-Type": "application/json" });
          res.end(
            JSON.stringify({
              stdout,
              stderr,
              returnCode,
            })
          );
        });
      })
      .listen(port, () => {
        console.info("Server started");
      });

    // Never return from this function
    await new Promise((r) => {});
  } else if (arg === "stop") {
    const targetPid = parseInt(fs.readFileSync(daemonPidFile, "utf8"), 10);
    console.info(`Stopping daemon with PID ${targetPid}`);
    process.kill(targetPid, "SIGTERM");
    process.exit(0);
  } else if (arg === "use") {
    // console.info("Using daemon for compilation");
    await new Promise(() => {
      http.get(
        `http://localhost:${port}/` +
          encodeURIComponent(JSON.stringify(process.argv.slice(2))),
        (res) => {
          // console.info("RES")
          let data = "";
          res.on("data", (chunk) => {
            data += chunk.toString();
          });
          res.on("end", () => {
            const response = JSON.parse(data);

            const { stdout, stderr, returnCode } = response;
            console.log(stdout);
            if (stderr) {
              console.error(stderr);
            }
            process.exit(returnCode);
          });
          res.on("error", (err) => {
            console.error("Error in response:", err);
            process.exit(1);
          });
        }
      );
    });
  } else {
    throw new Error(`Unknown arg ${arg}`);
  }
}

/**
 *
 * @param {string[]} sslcArgs Command-line arguments to sslc
 * @param {Uint8Array} [wasmBinary] A compiled binary, if bundler fails to bundle .wasm file
 * @returns {{stdout: string, stderr: string, returnCode: number}}
 */
async function compile(sslcArgs, wasmBinary) {
  const stdout = [];
  const stderr = [];

  try {
    const instance = await Module({
      print: (text) => stdout.push(text),
      printErr: (text) => stderr.push(text),
      noInitialRun: true,
      ...(wasmBinary
        ? {
            wasmBinary,
            locateFile: (p) => p,
          }
        : {}),
    });

    instance.FS.mkdir("/host");

    const cwd = path.parse(process.cwd());

    instance.FS.mount(
      // Using NODEFS instead of NODERAWFS because
      // NODERAWFS caused errors when the same module
      // runs the second time
      instance.NODEFS,
      {
        root: cwd.root,
      },
      "/host"
    );
    instance.FS.chdir(path.join("host", cwd.dir, cwd.name));

    const returnCode = instance.callMain(sslcArgs);

    instance.FS.chdir("/");
    instance.FS.unmount("/host");

    return {
      returnCode,
      stdout: stdout.join("\n"),
      stderr: stderr.join("\n"),
    };
  } catch (e) {
    return {
      returnCode: 1,
      stdout: stdout.join("\n"),
      stderr: stderr.join("\n") + `\nERROR: ${e.name} ${e.message} ${e.stack}`,
    };
  }
}

if (await mainWithDaemon()) {
  process.exit(0);
}

const { stdout, stderr, returnCode } = await compile(process.argv.slice(2));
console.log(stdout);
if (stderr) {
  console.error(stderr);
}
process.exit(returnCode);
