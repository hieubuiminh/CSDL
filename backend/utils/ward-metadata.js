const fs = require('node:fs/promises');
const path = require('node:path');
const crypto = require('node:crypto');

// Province/type are application configuration; the group's SQL schema is unchanged.
const metadataFile = process.env.WARD_METADATA_FILE || path.join(__dirname, '..', '..', 'data', 'ward-metadata.json');
let writeQueue = Promise.resolve();

async function loadWardMetadata() {
  let raw;
  try { raw = await fs.readFile(metadataFile, 'utf8'); }
  catch (error) {
    if (error.code === 'ENOENT') return Object.create(null);
    throw error;
  }
  const data = JSON.parse(raw);
  if (!data || typeof data !== 'object' || Array.isArray(data)) throw new Error('File cấu hình địa bàn không hợp lệ.');
  return Object.assign(Object.create(null), data);
}

function updateWardMetadata(id, metadata) {
  const operation = writeQueue.catch(() => {}).then(async () => {
    const data = await loadWardMetadata();
    data[id] = { province: metadata.province.trim(), unitType: metadata.unitType };
    await fs.mkdir(path.dirname(metadataFile), { recursive: true });
    const temporaryFile = `${metadataFile}.${crypto.randomUUID()}.tmp`;
    try {
      await fs.writeFile(temporaryFile, JSON.stringify(data, null, 2) + '\n', 'utf8');
      await fs.rename(temporaryFile, metadataFile);
    } finally {
      await fs.rm(temporaryFile, { force: true });
    }
  });
  writeQueue = operation;
  return operation;
}

module.exports = { loadWardMetadata, updateWardMetadata };
