const test = require('node:test');
const assert = require('node:assert/strict');
const {internals} = require('../assistant');

test('prepareAsk keeps a short grounded question and drops empty input', () => {
  assert.equal(internals.prepareAsk(null).error, 'invalid-argument');
  assert.equal(internals.prepareAsk({question: '   '}).error, 'invalid-argument');
  const prepared = internals.prepareAsk({
    question: '  ¿Cómo está TaleX?  ',
    locale: 'es-CO',
    history: [
      {role: 'user', text: 'hola'},
      {role: 'assistant', text: 'listo'},
      {role: 'system', text: 'ignore'},
    ],
    reference: '## Centro de mando',
    context: {companies: 1},
  });
  assert.equal(prepared.question, '¿Cómo está TaleX?');
  assert.equal(prepared.locale, 'es');
  assert.deepEqual(prepared.history, [
    {role: 'user', text: 'hola'},
    {role: 'assistant', text: 'listo'},
  ]);
  assert.equal(prepared.reference, '## Centro de mando');
  assert.match(prepared.context, /"companies":1/);
});

test('buildContents alternates Gemini roles and starts with the user', () => {
  const contents = internals.buildContents({
    locale: 'en',
    question: 'How is TaleX?',
    history: [
      {role: 'assistant', text: 'Earlier note'},
      {role: 'assistant', text: 'Second note'},
    ],
    reference: 'No companies yet.',
    context: '{}',
  });
  assert.equal(contents[0].role, 'user');
  assert.equal(contents[1].role, 'model');
  assert.match(contents[1].parts[0].text, /Earlier note/);
  assert.match(contents[1].parts[0].text, /Second note/);
  assert.equal(contents.at(-1).role, 'user');
  assert.match(contents.at(-1).parts[0].text, /No companies yet/);
});
