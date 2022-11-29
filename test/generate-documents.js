const rpn = require('request-promise-native');
const uuid = require('uuid').v4;
const fs = require('fs').promises;
const path = require('path');

const [ ,, url ] = process.argv;
const dataPath = path.join(__dirname, '..', 'data');

const nbrDocuments = 1000;

const ddoc = {
  "_id": "_design/test",
  "views": {
    "view": {
      "map": "function(doc) {\n  emit(doc.value); }",
    }
  }
};

const generateDatabase = async () => {
  console.log('Generating database');

  const dbName = `db${uuid()}`;
  await rpn.put({ url: `${url}/${dbName}`, json: true });

  const docs = Array.from({ length: nbrDocuments }).map(() => ({ _id: uuid(), value: uuid() }));
  await fs.writeFile(path.join(dataPath, `${dbName}.json`), JSON.stringify(docs));
  await rpn.post({ url: `${url}/${dbName}/_bulk_docs`, json: true, body: { docs: [ddoc, ...docs] } });

  const t = Date.now();

  await rpn.get({ url: `${url}/${dbName}/_design/test/_view/view?update_seq=true`, json: true });
  const result = await rpn.get({ url: `${url}/${dbName}/_design/test/_view/view?stale=ok&update_seq=true`, json: true });
  console.log({ ...result, rows: [] });

  console.log(`view indexing took ${Date.now() - t}`);
};

(async () => {
  await rpn.put({ url: `${url}/_users`, json: true });
  await generateDatabase();
  await generateDatabase();
  await generateDatabase();
  await generateDatabase();
})();
