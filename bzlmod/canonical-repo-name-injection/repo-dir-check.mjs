/*
 * Copyright 2024 EngFlow Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

import {
  ruleName, target, location, macroName, macroDir, repoName, repoDir, binDir,
} from './constants.js';

import * as path from 'node:path';
import * as fs from 'node:fs/promises';
import * as process from 'node:process';

console.log(`rule name: ${ruleName}\n`);

console.log(`target:    ${target}`);
console.log(`location:  ${location}\n`);

console.log(`macroName: ${macroName}`);
console.log(`macroDir:  ${macroDir}\n`);

console.log(`repoName:  ${repoName}`);
console.log(`repoDir:   ${repoDir}\n`);

console.log(`runfiles:  ${process.env.JS_BINARY__RUNFILES}`)
console.log(`PWD:       ${path.resolve()}`);
console.log(`binDir:    ${binDir}\n`);

async function checkDir() {
  const dirname = path.resolve(...arguments);
  await fs.access(dirname, fs.constants.R_OK | fs.constants.X_OK);
  return dirname;
}

try {
  const result = await Promise.any([
    checkDir(macroDir),
    checkDir(repoDir),
    checkDir(binDir, macroDir),
    checkDir(binDir, repoDir),
  ])
  console.log(`result:    ${result}`);

} catch (err) {
  console.error('repo directory not found:')
  console.error(err.errors ? err.errors.join('\n'): err);
  process.exit(1);
}
