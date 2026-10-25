import {randomUUID} from 'node:crypto';
import {findOne, insertOne} from '../domain/store.js';
import {ApiError} from '../http.js';
import {publicRow} from '../domain/rows.js';

const EMPLOYEE_RANGES = new Set([
  '1 – 10',
  '11 – 50',
  '51 – 200',
  '201 – 500',
  'Más de 500',
]);

const CULTURE_TRAITS = new Set([
  'Colaborativa',
  'Innovadora',
  'Orientada a resultados',
  'Cercana',
  'Estructurada',
  'Flexible',
  'Exigente',
  'De aprendizaje constante',
]);

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function text(value, max) {
  const next = String(value ?? '').trim();
  return next.length > max ? next.slice(0, max) : next;
}

function normalizeRange(value) {
  return String(value ?? '')
    .trim()
    .replace(/\s*[-–—]\s*/g, ' – ')
    .replace(/\s+/g, ' ');
}

function asList(value) {
  if (Array.isArray(value)) return value;
  if (typeof value === 'string' && value.trim()) {
    return value.split(',').map((item) => item.trim()).filter(Boolean);
  }
  return [];
}

function consentFlags(consent) {
  const payload = consent && typeof consent === 'object' ? consent : {};
  return {
    terms: Boolean(payload.aceptaTerminosYPolitica || payload.terms),
    data: Boolean(payload.autorizaTratamientoDatos || payload.dataProcessing),
    payload,
  };
}

function originOf(body) {
  const origin = body.origen && typeof body.origen === 'object' ? body.origen : {};
  return {
    utmSource: text(origin.utmSource ?? body.utmSource ?? body.utm_source, 160),
    utmMedium: text(origin.utmMedium ?? body.utmMedium ?? body.utm_medium, 160),
    utmCampaign: text(origin.utmCampaign ?? body.utmCampaign ?? body.utm_campaign, 160),
    referrer: text(origin.referrer ?? body.referrer, 500),
  };
}

function normalizeLead(body) {
  const companyName = text(body.nombreEmpresa ?? body.company_name ?? body.empresa, 120);
  const employeeRange = normalizeRange(body.rangoEmpleados ?? body.employee_range ?? body.tamano);
  const traits = asList(body.culturaPercibida ?? body.perceived_culture ?? body.rasgos);
  const comment = text(body.comentarioCultura ?? body.culture_comment ?? body.comentario, 280);
  const email = text(body.correo ?? body.email, 255).toLowerCase();
  const consent = consentFlags(body.consentimiento ?? body.consent);
  const origin = originOf(body);
  const consentPayload = consent.payload;
  const sourceUrl = text(consentPayload.urlOrigen ?? body.source_url, 500);
  const userAgent = text(consentPayload.navegador ?? body.user_agent, 500);

  if (companyName.length < 2) {
    throw new ApiError(400, 'invalid_company', 'El nombre de la empresa es obligatorio.');
  }
  if (!EMPLOYEE_RANGES.has(employeeRange)) {
    throw new ApiError(400, 'invalid_employee_range', 'Elige un rango de empleados válido.');
  }
  const perceivedCulture = [...new Set(traits.map((item) => String(item).trim()).filter(Boolean))];
  if (!perceivedCulture.length) {
    throw new ApiError(400, 'invalid_culture', 'Elige al menos un rasgo cultural.');
  }
  if (perceivedCulture.length > 3) {
    throw new ApiError(400, 'invalid_culture', 'Puedes elegir máximo 3 rasgos culturales.');
  }
  if (perceivedCulture.some((item) => !CULTURE_TRAITS.has(item))) {
    throw new ApiError(400, 'invalid_culture', 'Hay un rasgo cultural que no reconocemos.');
  }
  if (!EMAIL.test(email)) {
    throw new ApiError(400, 'invalid_email', 'El correo no es válido.');
  }
  if (!consent.terms || !consent.data) {
    throw new ApiError(
      400,
      'missing_consent',
      'Debes aceptar los términos y autorizar el tratamiento de datos.',
    );
  }

  return {
    companyName,
    employeeRange,
    perceivedCulture,
    comment: comment || null,
    email,
    consentTerms: consent.terms,
    consentData: consent.data,
    consentPayload: Object.keys(consent.payload).length ? consent.payload : null,
    ...origin,
    sourceUrl: sourceUrl || null,
    userAgent: userAgent || null,
  };
}

export async function createCultureLead(body) {
  const lead = normalizeLead(body || {});
  const now = new Date();
  const id = randomUUID();
  await insertOne('culture_leads', {
    id,
    company_name: lead.companyName,
    employee_range: lead.employeeRange,
    perceived_culture: lead.perceivedCulture,
    culture_comment: lead.comment,
    email: lead.email,
    consent_terms: lead.consentTerms,
    consent_data: lead.consentData,
    consent_payload: lead.consentPayload,
    utm_source: lead.utmSource || null,
    utm_medium: lead.utmMedium || null,
    utm_campaign: lead.utmCampaign || null,
    referrer: lead.referrer || null,
    source_url: lead.sourceUrl,
    user_agent: lead.userAgent,
    source: 'mi-cultura',
    status: 'new',
    created_at: now,
    updated_at: now,
  });
  const row = await findOne('culture_leads', {id});
  return {success: true, id, lead: publicRow(row)};
}
