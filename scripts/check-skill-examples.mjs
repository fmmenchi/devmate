// Every JSON example in a SKILL.md names its schema and validates against it
// (ADR 0004). A model copies the example more faithfully than the prose around
// it, so an example that contradicts its own rule is a defect for the gate.
//
// Fence an example as ```json <artefact>; it is checked against
// schemas/<artefact>.schema.json. A JSON block naming no schema fails.
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import Ajv2020 from 'ajv/dist/2020.js';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const skillsDir = join(root, 'skills');
const ajv = new Ajv2020({ allErrors: true, strict: true });
const fence = /^```json([^\n]*)\n([\s\S]*?)^```/gm;
let errors = 0;

const fail = (where, message) => {
  console.log(`ERROR  ${where}: ${message}`);
  errors += 1;
};

const skills = existsSync(skillsDir)
  ? readdirSync(skillsDir, { withFileTypes: true }).filter((d) =>
      d.isDirectory(),
    )
  : [];

for (const { name } of skills) {
  const file = join(skillsDir, name, 'SKILL.md');
  if (!existsSync(file)) continue; // the ai-skills gate already reported it
  const text = readFileSync(file, 'utf8');

  for (const [, info, body] of text.matchAll(fence)) {
    const artefact = info.trim();
    const where = `${name}/SKILL.md`;
    if (!artefact) {
      fail(
        where,
        'a ```json example names no schema — fence it as ```json <artefact>',
      );
      continue;
    }
    const schemaFile = join(root, 'schemas', `${artefact}.schema.json`);
    if (!existsSync(schemaFile)) {
      fail(
        where,
        `example names schemas/${artefact}.schema.json, which does not exist`,
      );
      continue;
    }
    let example;
    try {
      example = JSON.parse(body);
    } catch (e) {
      fail(where, `the ${artefact} example is not valid JSON: ${e.message}`);
      continue;
    }
    const validate = ajv.compile(JSON.parse(readFileSync(schemaFile, 'utf8')));
    if (!validate(example)) {
      for (const err of validate.errors) {
        fail(
          where,
          `${artefact} example ${err.instancePath || '/'} ${err.message}`,
        );
      }
    }
  }
}

console.log(`skill examples: ${skills.length} skill(s), ${errors} error(s)`);
process.exit(errors ? 1 : 0);
