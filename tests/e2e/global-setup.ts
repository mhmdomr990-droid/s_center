import 'dotenv/config';

import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';
import mysql from 'mysql2/promise';

const TEST_VIDEO_BASE64 =
  'AAAAIGZ0eXBpc29tAAACAGlzb20aXNvMmF2YzFtcDQxAAAC6G1vb3YAAABsbXZoZAAAAAB8J7+nfCe/pwAAA+gAAAPoAAEAAAEAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAAANUdHJhawAAAFx0a2hkAAAAA3wnv6d8J7+nAAAAAQAAAAAAAAPoAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAQAAAAAAAQAAAAEAAAAAAAkBlZHRzAAAAHGVsc3QAAAAAAAAAAQAAA+gAAAQAAAEAAAAAAdxtZGlhAAAAIG1kaGQAAAAAfCe/p3wnv6cAAAAoAAAAKFXEAAAAAAAtaGRscgAAAAAAAAAAdmlkZQAAAAAAAAAAAAAAAFZpZGVvSGFuZGxlcgAAAW9taW5mAAAAFHZtaGQAAAABAAAAAAAAAAAAAAAJZGluZgAAAB1kcmVmAAAAAAAAAAEAAAANdXJsIAAAAAEAAAEvc3RibAAAAKNzdHNkAAAAAAAAAAEAAACTYXZjMQAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAEAAQBIAAAAAEgAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABj//wAAADVhdmNDAWQAFv/hABlnZAAMrNlAQUHlhAAAAwBAAAAMD6gAAAMAAAMAAx5HixckAQAGaOvjyyLA/fj4AAAAABBzdHRzAAAAAAAAAAEAAAABAAAAKAAAAAAcc3RzYwAAAAAAAAABAAAAAQAAAAEAAAABAAAAFHN0c3oAAAAAAAAAAAAAAQAAALIAAAAUc3RjbwAAAAAAAAABAAAAkAAAAGJtZGF0AAACrQYF//+p3EXpvebZSLeWLNgg2SPu73gyNjQgLSBjb3JlIDE2NCByMzEwOCBmZjlhY2QxIC0gSC4yNjQvTVBFRy00IEFWQyBjb2RlYyAtIENvcHlsZWZ0IDIwMDMtMjAyMiAtIGh0dHA6Ly93d3cudmlkZW9sYW4ub3JnL3g0NjQuaHRtbCAtIG9wdGlvbnM6IGNhYmFjPTEgcmVmPTEgZGVibG9jaz0xOjA6MCBhbmFseXNlPTB4MToxMTEgbWU9aGV4IHN1Ym1lPTcg cHN5PTEgcHN5X3JkPTEuMDA6MC4wMCBtaXhlZF9yZWY9MCBtZV9yYW5nZT0xNiBjaHJvbWFfbWU9MSB0cmVsbGlzPTEgOHg4ZGN0PTEgY3FtPTAgZGVhZHpvbmU9MjEsMTEgZmFzdF9wc2tpcD0xIGNocm9tYV9xcF9vZmZzZXQ9LTItIHRocmVhZHM9MSBsb29rYWhlYWRfdGhyZWFkcz0xIHNsaWNlZF90aHJlYWRzPTAgbnI9MCBkZWNpbWF0ZT0xIGludGVybGFjZWQ9MCBibHVyYXk9MCBjb25zdHJhaW5lZF9pbnRyYT0wIGJmcmFtZXM9MCB3ZWlnaHRwPTEga2V5aW50PTI1IGtleWludF9taW49MyBzY2VuZWN1dD00MCBpbnRyYV9yZWZyZXNoPTAgcmNfbG9va2FoZWFkPTI1IHJjPWNyZiBtYnRyZWU9MSBjcmY9MjMuMCBxY29tcD0wLjYwIHFwbWluPTAgcXBtYXg9NjkgcXBzdGVwPTQgaXBfcmF0aW89MS40MCBhcT0xOjEuMDAAIAAAABJliIQAOv8s3xEhEAA=';

function ensureTestVideoFile() {
  const dir = path.resolve(process.cwd(), 'tests', 'e2e', 'fixtures');
  const filePath = path.join(dir, 'tiny.mp4');
  fs.mkdirSync(dir, { recursive: true });

  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, Buffer.from(TEST_VIDEO_BASE64.replace(/\s+/g, ''), 'base64'));
  }

  return filePath;
}

function ensureTestDatabaseName() {
  if (!process.env.DB_NAME_TEST) {
    if (!process.env.DB_NAME) {
      throw new Error('DB_NAME is required to derive DB_NAME_TEST.');
    }
    process.env.DB_NAME_TEST = `${process.env.DB_NAME}_e2e`;
  }
}

async function ensureTestSchemaExists() {
  const host = process.env.DB_HOST || 'localhost';
  const port = Number(process.env.DB_PORT || '3306');
  const user = process.env.DB_USER || 'root';
  const password = process.env.DB_PASSWORD || '';
  const schema = process.env.DB_NAME_TEST;

  if (!schema) {
    throw new Error('DB_NAME_TEST is required after test database name derivation.');
  }

  const connection = await mysql.createConnection({ host, port, user, password });
  try {
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${schema}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`);
  } finally {
    await connection.end();
  }
}

function seedAdmin() {
  execSync('npm run seed:admin', {
    stdio: 'inherit',
    env: {
      ...process.env,
      NODE_ENV: 'test',
    },
  });
}

async function globalSetup() {
  ensureTestDatabaseName();
  await ensureTestSchemaExists();
  ensureTestVideoFile();
  seedAdmin();
}

export default globalSetup;
