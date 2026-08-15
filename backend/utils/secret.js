import fs from 'fs';

// Lit d'abord <NAME>_FILE (docker secret monté en fichier),
// sinon retombe sur la variable d'env <NAME> (dev local).
export function secret(name) {
  const file = process.env[`${name}_FILE`];
  if (file && fs.existsSync(file)) {
    return fs.readFileSync(file, 'utf8').trim();
  }
  return process.env[name];
}