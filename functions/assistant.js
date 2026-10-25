const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineSecret, defineString} = require('firebase-functions/params');

const geminiApiKey = defineSecret('GEMINI_API_KEY');
const DEFAULT_MODEL = 'gemini-3.8-flash';
const geminiModel = defineString('GEMINI_MODEL', {default: DEFAULT_MODEL});

const SYSTEM_PROMPT = [
  'You are TaleXito, the company-culture assistant inside TaleX.',
  'Your job is the culture of the company that is open: values, ways of working, and what the company looks for.',
  'If the person needs to locate something else, tell them which TaleX screen holds it. Do not change records from the chat.',
  'Answer in the locale requested by the user: Spanish when locale is es, English when locale is en.',
  'Use concise Markdown.',
  'Use only facts present in the reference answer or the structured context.',
  'Do not invent culture, counts, names, or completed actions.',
  'Do not hire, reject, or decide for the company.',
  'If the reference is the fixed out-of-scope reply, repeat that limit. Do not answer the outside question.',
].join(' ');

function clip(value, max) {
  if (typeof value !== 'string') return '';
  const clean = value.replace(/\u0000/g, '').trim();
  return clean.length > max ? clean.slice(0, max) : clean;
}

function normalizeHistory(value) {
  if (!Array.isArray(value)) return [];
  const turns = [];
  for (const item of value) {
    if (!item || typeof item !== 'object') continue;
    const role = item.role === 'assistant' ? 'assistant' : item.role === 'user' ? 'user' : '';
    const text = clip(item.text, 4000);
    if (!role || !text) continue;
    turns.push({role, text});
  }
  return turns.slice(-8);
}

function clipJson(value, max) {
  if (value == null) return '{}';
  let encoded = '';
  try {
    encoded = JSON.stringify(value);
  } catch (_) {
    return '{}';
  }
  if (!encoded || encoded.length > max) return '{}';
  return encoded;
}

function prepareAsk(data) {
  if (!data || typeof data !== 'object') return {error: 'invalid-argument'};
  const question = clip(data.question, 2000);
  if (!question) return {error: 'invalid-argument'};
  const locale = String(data.locale || 'es').toLowerCase().startsWith('en') ? 'en' : 'es';
  return {
    locale,
    question,
    history: normalizeHistory(data.history),
    reference: clip(data.reference, 12000),
    context: clipJson(data.context, 16000),
  };
}

function buildContents(prepared) {
  const contents = [];
  const push = (role, text) => {
    const geminiRole = role === 'assistant' ? 'model' : 'user';
    const last = contents[contents.length - 1];
    if (last && last.role === geminiRole) {
      last.parts[0].text += `\n\n${text}`;
      return;
    }
    contents.push({role: geminiRole, parts: [{text}]});
  };
  for (const turn of prepared.history) push(turn.role, turn.text);
  push('user', [
    `Locale: ${prepared.locale}`,
    `Question: ${prepared.question}`,
    '',
    'Reference answer:',
    prepared.reference || '(none)',
    '',
    'Structured context:',
    prepared.context,
  ].join('\n'));
  if (contents[0] && contents[0].role === 'model') {
    contents.unshift({
      role: 'user',
      parts: [{text: 'Continue the TaleX conversation.'}],
    });
  }
  return contents;
}

async function callGeminiText({apiKey, model, contents}) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 20000);
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
      body: JSON.stringify({
        systemInstruction: {parts: [{text: SYSTEM_PROMPT}]},
        contents,
        generationConfig: {temperature: 0.2, maxOutputTokens: 1200},
      }),
      signal: controller.signal,
    });
    if (!response.ok) {
      const reason = await response.text().catch(() => '');
      const code = response.status === 429 || response.status >= 500 ? 'unavailable' : 'internal';
      throw new HttpsError(code, `gemini_${response.status} ${reason.slice(0, 180)}`);
    }
    const payload = await response.json();
    const candidate = payload.candidates && payload.candidates[0];
    const output = candidate && candidate.content && candidate.content.parts
      ? candidate.content.parts.map((part) => part.text || '').join('').trim()
      : '';
    if (!output) throw new HttpsError('unavailable', 'empty_model');
    return output.length > 12000 ? output.slice(0, 12000) : output;
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    if (error.name === 'AbortError') throw new HttpsError('unavailable', 'gemini_timeout');
    throw new HttpsError('unavailable', 'gemini_unavailable');
  } finally {
    clearTimeout(timer);
  }
}

const askAssistant = onCall(
  {
    region: 'us-central1',
    cors: true,
    invoker: 'public',
    secrets: [geminiApiKey],
    timeoutSeconds: 30,
    memory: '256MiB',
  },
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'errorNeedSignIn');
    const prepared = prepareAsk(request.data);
    if (prepared.error) throw new HttpsError(prepared.error, 'invalid_question');
    const apiKey = (process.env.GEMINI_API_KEY || '').trim();
    if (!apiKey) throw new HttpsError('failed-precondition', 'assistant_not_configured');
    const model = (process.env.GEMINI_MODEL || geminiModel.value() || DEFAULT_MODEL).trim();
    const text = await callGeminiText({
      apiKey,
      model,
      contents: buildContents(prepared),
    });
    return {text};
  },
);

exports.askAssistant = askAssistant;
exports.internals = {prepareAsk, buildContents, clip, normalizeHistory};
