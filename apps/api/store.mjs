import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { dirname } from 'node:path';

const empty = () => ({
  users: [], profiles: [], conversations: [], messages: [], cardDrafts: [], cards: [],
  abilities: [], reports: [], memories: [], settings: [], directions: [],
  connectionRequests: [], partnerConversations: [], partnerMessages: [], consents: [], exports: [],
});

export class JsonStore {
  constructor(file) { this.file = file; this.queue = Promise.resolve(); }
  async read() {
    if (!existsSync(this.file)) return empty();
    const value = { ...empty(), ...JSON.parse(await readFile(this.file, 'utf8')) };
    for (const key of Object.keys(empty())) value[key] ||= [];
    return value;
  }
  async mutate(change) {
    const run = this.queue.then(async () => {
      const data = await this.read();
      const result = await change(data);
      await mkdir(dirname(this.file), { recursive: true });
      const temporary = `${this.file}.tmp`;
      await writeFile(temporary, JSON.stringify(data, null, 2));
      await rename(temporary, this.file);
      return result;
    });
    this.queue = run.catch(() => {});
    return run;
  }
}
