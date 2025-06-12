#!/usr/bin/env node

//
// This is a Node.js wrapper for the SSL Compiler (sslc).
// It allows to compile SSL files using the Node.js environment.
//
// Use it the same way as you would use the `sslc` command-line tool.
//

import path from "path";
import Module from "./sslc.mjs";

/**
 *
 * @param {string[]} sslcArgs Command-line arguments to sslc
 * @param {Uint8Array} [wasmBinary] A compiled binary, if bundler fails to bundle .wasm file
 * @param {string} [cwd] Current working directory to compile in.
 * @returns {{stdout: string, stderr: string, returnCode: number}}
 */
async function compile(sslcArgs, wasmBinary, cwd) {
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

    const cwdPath = path.parse(cwd || process.cwd());

    // console.info("DEBUG cwd", cwd);

    instance.FS.mount(
      // Using NODEFS instead of NODERAWFS because
      // NODERAWFS caused errors when the same module
      // runs the second time
      instance.NODEFS,
      {
        root: cwdPath.root,
      },
      "/host"
    );

    // console.info("DEBUG after mount");

    instance.FS.chdir(path.join("host", cwdPath.dir, cwdPath.name));

    // console.info("DEBUG after chdir");

    const returnCode = instance.callMain(sslcArgs);

    // console.info("DEBUG after call");

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

const { stdout, stderr, returnCode } = await compile(process.argv.slice(2));
console.log(stdout);
if (stderr) {
  console.error(stderr);
}
process.exit(returnCode);
