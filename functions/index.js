const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const admin = require('firebase-admin');
const {onCall, onRequest, HttpsError} = require('firebase-functions/v2/https');
const {defineString} = require('firebase-functions/params');
const nodemailer = require('nodemailer');

if (!admin.apps.length) {
  admin.initializeApp();
}

const smtpHost = defineString('SMTP_HOST', {default: ''});
const smtpUser = defineString('SMTP_USER', {default: ''});
const smtpPass = defineString('SMTP_PASS', {default: ''});
const smtpFrom = defineString('SMTP_FROM', {default: ''});
const smtpPort = defineString('SMTP_PORT', {default: '587'});

function headline(locale, situation) {
  const en = locale === 'en';
  const lines = {
    first_email: en
      ? 'Ready to discover a new way of understanding talent?'
      : '¿Listo para conocer una nueva forma de entender el talento?',
    account_created: en
      ? 'Your TaleX workspace is ready. Shall we begin?'
      : 'Tu espacio en TaleX ya está listo. ¿Comenzamos?',
    first_login: en
      ? 'Welcome to TaleX. This is the start of something we want to build with you.'
      : 'Bienvenido a TaleX. Este es el comienzo de algo que queremos construir contigo.',
    first_payment: en
      ? 'You made a good decision. Welcome officially to TaleX.'
      : 'Tomaste una buena decisión. Bienvenido oficialmente a TaleX.',
    first_process: en
      ? 'You took the first step. Now it gets interesting.'
      : 'Ya diste el primer paso. Ahora comienza lo interesante.',
    first_evaluation: en
      ? 'Everything is ready. Now let’s let the data tell the story.'
      : 'Todo está listo. Ahora dejemos que los datos nos cuenten la historia.',
    first_respondent_invited: en
      ? 'Your process is taking shape. Someone new has been invited to take part.'
      : 'Tu proceso ya está tomando forma. Hay una nueva persona invitada a participar.',
    respondent_invite: en
      ? 'We’d like to get to know you a little better. Will you join us?'
      : 'Queremos conocerte un poco mejor. ¿Nos acompañas?',
    respondent_started: en
      ? 'You’ve started. Take your time and answer at your own pace.'
      : 'Ya comenzaste. Tómate tu tiempo y responde con tranquilidad.',
    respondent_incomplete: en
      ? 'You’re one step away. When you’re ready, you can continue.'
      : 'Te quedaste a un paso. Cuando estés listo, puedes continuar.',
    respondent_complete: en
      ? 'That’s it. Thank you for sharing a part of yourself with us.'
      : 'Listo. Gracias por compartir una parte de ti con nosotros.',
    evaluation_received: en
      ? 'We have your answers. Now our work begins.'
      : 'Ya tenemos tus respuestas. Ahora comienza nuestro trabajo.',
    results_ready: en
      ? 'It’s time to see what we found.'
      : 'Llegó el momento de conocer lo que encontramos.',
    company_followup: en
      ? 'We’re getting to know a little more of what you’re building with TaleX.'
      : 'Cada vez conocemos un poco más de lo que estás construyendo con TaleX.',
    admin_added_user: en
      ? 'Someone thought you should be part of this. You already have a space in TaleX.'
      : 'Alguien pensó que debías ser parte de esto. Ya tienes un espacio en TaleX.',
    company_new_user: en
      ? 'Your team opened the doors to TaleX. Welcome.'
      : 'Tu equipo te abrió las puertas de TaleX. Bienvenido.',
    payment_reminder: en
      ? 'We want to help you keep your process moving.'
      : 'Queremos ayudarte a mantener tu proceso en marcha.',
    payment_confirmed: en
      ? 'All set. Everything is in order and we can continue.'
      : '¡Listo! Todo está en orden y podemos continuar.',
    process_finished: en
      ? 'We’ve reached the end of this process. Thank you for making it part of TaleX.'
      : 'Llegamos al final de este proceso. Gracias por hacerlo parte de TaleX.',
    returning_client: en
      ? 'You’re not new here anymore. Let’s keep building together.'
      : 'Ya no eres nuevo por aquí. Sigamos construyendo juntos.',
    long_term_client: en
      ? 'Thank you for still being part of the TaleX family.'
      : 'Gracias por seguir haciendo parte de la familia TaleX.',
    recovery_pin: en
      ? 'Let’s get you back into your TaleX workspace.'
      : 'Recupera el acceso a tu espacio TaleX. Estamos contigo.',
  };
  return lines[situation] || lines.account_created;
}

function resolveSituation(type, situation) {
  const key = String(situation || '').trim();
  const known = new Set([
    'first_email',
    'account_created',
    'first_login',
    'first_payment',
    'first_process',
    'first_evaluation',
    'first_respondent_invited',
    'respondent_invite',
    'respondent_started',
    'respondent_incomplete',
    'respondent_complete',
    'evaluation_received',
    'results_ready',
    'company_followup',
    'admin_added_user',
    'company_new_user',
    'payment_reminder',
    'payment_confirmed',
    'process_finished',
    'returning_client',
    'long_term_client',
    'recovery_pin',
  ]);
  if (known.has(key)) return key;
  if (type === 'assessment_complete') return 'respondent_complete';
  if (type === 'recovery_pin') return 'recovery_pin';
  return 'company_new_user';
}

function copy(locale, type, situation) {
  const en = locale === 'en';
  const respondent =
    type === 'respondent_pin' ||
    type === 'respondent_invite';
  const invite = type === 'respondent_invite';
  const recovery = type === 'recovery_pin';
  const completed = type === 'assessment_complete';

  return {
    hello: (name) => {
      if (en) return `Hi ${name || 'there'},`;
      return name ? `Hola ${name},` : 'Hola,';
    },

    intro: (company, vacancy) => {
      if (recovery) {
        return en
          ? 'We received a request to reset your TaleX password. Enter this PIN on the recovery screen to continue.'
          : 'Recibimos una solicitud para restablecer tu contraseña de TaleX. Ingresa este PIN en la pantalla de recuperación para continuar.';
      }

      if (completed) {
        return en
          ? `You finished the assessment${vacancy ? ` for ${vacancy}` : ''}${company ? ` at ${company}` : ''}.`
          : `Finalizaste la evaluación${vacancy ? ` de ${vacancy}` : ''}${company ? ` en ${company}` : ''} con éxito.`;
      }

      if (invite) {
        return en
          ? vacancy
            ? `You were invited to a TaleX assessment for ${vacancy}${company ? ` at ${company}` : ''}. Open the invitation to begin your process.`
            : `You were invited to a TaleX assessment${company ? ` for ${company}` : ''}. Open the invitation to begin your process.`
          : vacancy
            ? `Te invitaron a una evaluación en TaleX para ${vacancy}${company ? ` en ${company}` : ''}. Abre la invitación para comenzar tu proceso.`
            : `Te invitaron a una evaluación en TaleX${company ? ` para ${company}` : ''}. Abre la invitación para comenzar tu proceso.`;
      }

      if (respondent) {
        return en
          ? vacancy
            ? `You were invited to a TaleX assessment for ${vacancy}${company ? ` at ${company}` : ''}. Create your account at TaleX and enter this PIN.`
            : `You were invited to a TaleX assessment${company ? ` for ${company}` : ''}. Create your account at TaleX and enter this PIN.`
          : vacancy
            ? `Te invitaron a una evaluación en TaleX para ${vacancy}${company ? ` en ${company}` : ''}. Crea tu cuenta en Registrarse e ingresa este PIN.`
            : `Te invitaron a una evaluación en TaleX${company ? ` para ${company}` : ''}. Crea tu cuenta en Registrarse e ingresa este PIN.`;
      }

      return en
        ? `A TaleX workspace was created for ${company || 'your company'}. Create your account and enter this PIN.`
        : `Se creó un espacio TaleX para ${company || 'tu empresa'}. Crea tu cuenta en Registrarse e ingresa este PIN.`;
    },

    pinLabel: recovery
      ? (en ? 'Your recovery PIN' : 'Tu PIN de recuperación')
      : (en ? 'Your activation PIN' : 'Tu PIN de activación'),

    pinTtl: en
      ? 'This PIN expires in 15 minutes.'
      : 'Este PIN caduca a los 15 minutos.',

    next: recovery
      ? (en
        ? 'Then you will set a new password. If you did not request this, you can ignore this email.'
        : 'Después crearás una nueva contraseña. Si no pediste este cambio, ignora este mensaje.')
      : completed
        ? ''
        : invite
          ? (en
            ? 'Use the button below to open your invitation.'
            : 'Usa el botón de abajo para abrir tu invitación.')
          : (en
            ? 'You can also create the account with Google and then enter this PIN.'
            : 'También puedes crear la cuenta con Google y luego ingresar este PIN.'),

    headline: respondent || completed
      ? ''
      : headline(locale, resolveSituation(type, situation)),

    cta: completed
      ? ''
      : invite
        ? (en ? 'Start assessment' : 'Comenzar evaluación')
        : (en ? 'Open TaleX' : 'Abrir TaleX'),

    footer: completed
      ? ''
      : recovery
      ? (en
        ? 'TaleX sent this message because someone requested a password reset for this email.'
        : 'TaleX envió este mensaje porque alguien pidió restablecer la contraseña de este correo.')
      : en
        ? respondent
          ? 'TaleX measures affinity with a vacancy profile. This message was sent because a company invited you to an assessment.'
          : 'TaleX helps teams understand affinity. This message was sent because an administrator invited you.'
        : respondent
          ? 'TaleX mide afinidad con el perfil de una vacante. Recibiste este mensaje porque una empresa te invitó a una evaluación.'
          : 'TaleX ayuda a los equipos a entender la afinidad. Recibiste este mensaje porque un administrador te invitó.',

    subject: (company, vacancy) => {
      if (recovery) {
        return en
          ? 'Your TaleX recovery PIN'
          : 'Tu PIN de recuperación TaleX';
      }

      if (completed) {
        return en
          ? 'You finished your TaleX assessment'
          : 'Finalizaste tu evaluación en TaleX';
      }

      if (invite) {
        return en
          ? `Your TaleX assessment${vacancy ? ` for ${vacancy}` : ''}`
          : `Tu evaluación en TaleX${vacancy ? ` para ${vacancy}` : ''}`;
      }

      if (respondent) {
        return en
          ? `Your TaleX PIN${vacancy ? ` for ${vacancy}` : ''}`
          : `Tu PIN de TaleX${vacancy ? ` para ${vacancy}` : ''}`;
      }

      return en
        ? `Your TaleX PIN for ${company || 'your company'}`
        : `Tu PIN de TaleX para ${company || 'tu empresa'}`;
    },
  };
}

const brandFiles = [
  {key: 'logo', file: 't_fondo_claro-2.png'},
];

const brandHashes = Object.fromEntries(
  brandFiles.map((item) => {
    const buffer = fs.readFileSync(path.join(__dirname, 'brand', item.file));
    return [
      item.key,
      crypto.createHash('sha256').update(buffer).digest('hex').slice(0, 20),
    ];
  }),
);

function brandImageUrls() {
  const project = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || 'talex-platform';
  const base = `https://us-central1-${project}.cloudfunctions.net/mailBrand`;
  return {
    logo: `${base}?k=${brandHashes.logo}`,
  };
}

exports.mailBrand = onRequest(
  {
    region: 'us-central1',
    cors: true,
    invoker: 'public',
  },
  (request, response) => {
    const id = String(request.query.k || '').trim();
    const item = brandFiles.find((entry) => brandHashes[entry.key] === id);
    if (!item) {
      response.status(404).end();
      return;
    }
    response.set('Content-Type', 'image/png');
    response.set('Cache-Control', 'public, max-age=31536000, immutable');
    response.set('X-Content-Type-Options', 'nosniff');
    response.set('Content-Disposition', 'inline');
    response.send(fs.readFileSync(path.join(__dirname, 'brand', item.file)));
  },
);

function html({
  locale,
  type,
  firstName,
  companyName,
  vacancyName,
  pin,
  appUrl,
  situation,
  images,
}) {
  const t = copy(locale, type, situation);

  const logo = images.logo;

  const pinBlock = pin
    ? `
        <div style="background:#F3F8FD;border:1px solid #C5DCF0;border-radius:12px;padding:20px;text-align:center;">
          <div style="font-size:12px;letter-spacing:1px;text-transform:uppercase;color:#1D7BD6;font-weight:700;">
            ${t.pinLabel}
          </div>
          <div style="margin-top:8px;font-size:36px;letter-spacing:8px;font-weight:700;color:#071326;">
            ${pin}
          </div>
          <div style="margin-top:10px;font-size:13px;color:#8DC53F;font-weight:600;">
            ${t.pinTtl}
          </div>
        </div>
      `
    : '';

  return `<!DOCTYPE html>
<html lang="${locale === 'en' ? 'en' : 'es'}">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
</head>

<body style="margin:0;padding:0;background:#F4F7FA;font-family:Arial,Helvetica,sans-serif;color:#071326;">

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#F4F7FA;padding:32px 16px;">
    <tr>
      <td align="center">

        <table role="presentation" width="560" cellspacing="0" cellpadding="0"
          style="max-width:560px;width:100%;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 12px 40px rgba(7,19,38,0.08);">

          <tr>
            <td style="background:#05060A;padding:22px 24px 16px;">
              <table role="presentation" cellspacing="0" cellpadding="0">
                <tr>

                  <td valign="middle" style="padding-right:14px;">
                    <img
                      src="${logo}"
                      alt=""
                      width="48"
                      height="48"
                      style="display:block;width:48px;height:48px;border:0;"
                    />
                  </td>

                  <td valign="middle">
                    <div style="font-size:22px;line-height:1.1;font-weight:700;color:#ffffff;letter-spacing:0.2px;">
                      TaleX
                    </div>

                    ${t.headline ? `<div style="margin-top:6px;font-size:13px;line-height:1.4;color:#ffffff;">
                      ${t.headline}
                    </div>` : ''}
                  </td>

                </tr>
              </table>
            </td>
          </tr>

          <tr>
            <td>
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                <tr>
                  <td style="height:4px;width:50%;background:#1D7BD6;"></td>
                  <td style="height:4px;width:50%;background:#8DC53F;"></td>
                </tr>
              </table>
            </td>
          </tr>

          <tr>
            <td style="padding:32px;">

              <p style="margin:0 0 16px;font-size:16px;">
                ${t.hello(firstName)}
              </p>

              <p style="margin:0 0 24px;font-size:15px;line-height:1.55;color:#45464A;">
                ${t.intro(companyName, vacancyName)}
              </p>

              ${pinBlock}

              ${t.next ? `<p style="margin:24px 0;font-size:15px;line-height:1.55;color:#45464A;">
                ${t.next}
              </p>` : ''}

              ${t.cta ? `<a
                href="${appUrl}"
                style="display:inline-block;background:#1D7BD6;color:#ffffff;text-decoration:none;padding:12px 22px;border-radius:8px;font-weight:700;"
              >
                ${t.cta}
              </a>` : ''}

            </td>
          </tr>

          ${t.footer ? `<tr>
            <td style="padding:0 20px 16px;font-size:12px;line-height:1.5;color:#76777C;">
              ${t.footer}
            </td>
          </tr>` : ''}

        </table>

      </td>
    </tr>
  </table>

</body>
</html>`;
}

function smtpConfig() {
  const host = process.env.SMTP_HOST || smtpHost.value();
  const user = process.env.SMTP_USER || smtpUser.value();
  const pass = process.env.SMTP_PASS || smtpPass.value();
  const from = process.env.SMTP_FROM || smtpFrom.value() || user;
  const port = Number(process.env.SMTP_PORT || smtpPort.value() || '465');
  return {host, user, pass, from, port};
}

function createTransport(host, user, pass, port) {
  return nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    requireTLS: port === 587,
    auth: {user, pass},
    family: 4,
    connectionTimeout: 25000,
    greetingTimeout: 25000,
    socketTimeout: 25000,
    tls: {servername: host, minVersion: 'TLSv1.2'},
  });
}

async function sendWithFallback({host, user, pass, from, preferredPort, mail}) {
  const ports = [...new Set([preferredPort, 465, 587])].filter(
    (port) => port === 465 || port === 587,
  );
  let lastError;
  for (const port of ports) {
    const transporter = createTransport(host, user, pass, port);
    try {
      await transporter.sendMail(mail);
      console.info('sendInviteEmail sent', {port, to: mail.to});
      return;
    } catch (error) {
      lastError = error;
      console.error('sendInviteEmail SMTP error', {
        port,
        code: error.code,
        command: error.command,
        response: error.response,
        message: error.message,
      });
    }
  }
  throw lastError || new Error('SMTP send failed.');
}

exports.sendInviteEmail = onCall(
  {
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 60,
    invoker: 'public',
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Sign in required.');
    }
    const {host, user, pass, from, port} = smtpConfig();
    console.info('sendInviteEmail smtp ready', {
      hostSet: Boolean(host),
      userSet: Boolean(user),
      passSet: Boolean(pass),
      port,
    });
    if (!host || !user || !pass) {
      throw new HttpsError(
        'failed-precondition',
        'SMTP is not configured.',
      );
    }
    const payload = request.data || {};

    const to = String(payload.to || '').trim();
    const pin = String(payload.pin || '').trim();
    const token = String(payload.token || '').trim();

    const locale = payload.locale === 'en' ? 'en' : 'es';

    const type = payload.type === 'respondent_invite'
      ? 'respondent_invite'
      : payload.type === 'respondent_pin'
        ? 'respondent_pin'
        : payload.type === 'assessment_complete'
          ? 'assessment_complete'
          : payload.type === 'recovery_pin'
            ? 'recovery_pin'
            : 'recruiter_pin';

    const completed = type === 'assessment_complete';
    const respondentInvite = type === 'respondent_invite';

    if (!to.includes('@')) {
      throw new HttpsError(
        'invalid-argument',
        'Invalid invite payload.',
      );
    }

    if (respondentInvite && !token) {
      throw new HttpsError(
        'invalid-argument',
        'Invitation token required.',
      );
    }

    if (!respondentInvite && !completed && pin.length < 6) {
      throw new HttpsError(
        'invalid-argument',
        'Invalid invite payload.',
      );
    }
    const situation = resolveSituation(type, payload.situation);
    const firstName = String(payload.firstName || '').trim();
    const companyName = String(payload.companyName || '').trim();
    const vacancyName = String(payload.vacancyName || '').trim();
    const appUrl = String(
      payload.appUrl || 'https://talex-platform.web.app',
        ).replace(/\/$/, '');
        
        const t = copy(locale, type, situation);
        const images = brandImageUrls();
        
        const registerUrl = `${appUrl}/#/register`;
        const respondentInviteUrl = `${appUrl}/#/assessment?token=${encodeURIComponent(token)}`;
        
        const actionUrl = respondentInvite
          ? respondentInviteUrl
          : registerUrl;
    try {
      await sendWithFallback({
        host,
        user,
        pass,
        from,
        preferredPort: port,
        mail: {
          from: `TaleX <${from}>`,
          to,
          subject: t.subject(companyName, vacancyName),
          text: completed
          ? `${t.hello(firstName)}\n${t.intro(companyName, vacancyName)}`
          : respondentInvite
            ? `${t.hello(firstName)}\n${t.intro(companyName, vacancyName)}\n${t.next}\n${respondentInviteUrl}`
            : `${t.hello(firstName)}\n${t.intro(companyName, vacancyName)}\n${t.pinLabel}: ${pin}\n${t.pinTtl}\n${t.next}\n${registerUrl}`,

        html: html({
          locale,
          type,
          situation,
          firstName,
          companyName,
          vacancyName,
          pin: completed || respondentInvite ? '' : pin,
          appUrl: actionUrl,
          images,
        }),
        },
      });
    } catch (error) {
      throw new HttpsError(
        'internal',
        error.message || 'SMTP send failed.',
      );
    }
    return {ok: true};
  },
);

async function deleteByQuery(query) {
  const snap = await query.get();
  const ids = [];
  for (const doc of snap.docs) {
    ids.push(doc.id);
    await doc.ref.delete();
  }
  return ids;
}

exports.purgeUserByEmail = onCall(
  {
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 60,
    invoker: 'public',
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Sign in required.');
    }
    const caller = await admin.firestore().collection('users').doc(request.auth.uid).get();
    if (caller.data()?.role !== 'superadmin') {
      throw new HttpsError('permission-denied', 'SuperAdmin required.');
    }
    if (request.data?.allCompanies === true) {
      const db = admin.firestore();
      const deleted = {
        companies: [],
        vacancies: [],
        candidates: [],
        invites: [],
        users: [],
      };
      const companies = await db.collection('companies').get();
      for (const company of companies.docs) {
        const companyId = company.id;
        deleted.companies.push(companyId);
        deleted.vacancies.push(
          ...(await deleteByQuery(db.collection('vacancies').where('companyId', '==', companyId))),
        );
        const companyCandidates = await db
          .collection('candidates')
          .where('companyId', '==', companyId)
          .get();
        for (const doc of companyCandidates.docs) {
          deleted.candidates.push(doc.id);
          await db.collection('evaluations').doc(doc.id).delete().catch(() => {});
          await doc.ref.delete();
        }
        deleted.invites.push(
          ...(await deleteByQuery(
            db.collection('activation_invites').where('companyId', '==', companyId),
          )),
        );
        await company.ref.delete();
      }
      const leftoverInvites = await db.collection('activation_invites').get();
      for (const doc of leftoverInvites.docs) {
        deleted.invites.push(doc.id);
        await doc.ref.delete();
      }
      const users = await db.collection('users').get();
      for (const doc of users.docs) {
        const data = doc.data() || {};
        if (data.role === 'superadmin') continue;
        const hadCompany = Boolean(data.companyId) ||
          data.role === 'company_admin' ||
          data.role === 'recruiter' ||
          data.role === 'respondent';
        if (!hadCompany) continue;
        deleted.users.push(doc.id);
        await doc.ref.delete();
        await admin.auth().deleteUser(doc.id).catch(() => {});
      }
      return {ok: true, deleted};
    }
    const email = String(request.data?.email || '').trim().toLowerCase();
    if (!email.includes('@')) {
      throw new HttpsError('invalid-argument', 'Email required.');
    }
    const db = admin.firestore();
    const deleted = {users: [], invites: [], companies: [], vacancies: [], candidates: []};
    let authUid = null;
    try {
      authUid = (await admin.auth().getUserByEmail(email)).uid;
    } catch (_) {
      authUid = null;
    }
    deleted.invites = await deleteByQuery(
      db.collection('activation_invites').where('email', '==', email),
    );
    const inviteDoc = await db.collection('activation_invites').doc(email).get();
    if (inviteDoc.exists) {
      await inviteDoc.ref.delete();
      deleted.invites.push(email);
    }
    const userDocs = await db.collection('users').where('email', '==', email).get();
    const companyIds = new Set();
    for (const doc of userDocs.docs) {
      deleted.users.push(doc.id);
      if (doc.data().companyId) companyIds.add(doc.data().companyId);
      await doc.ref.delete();
    }
    if (authUid) {
      const byUid = await db.collection('users').doc(authUid).get();
      if (byUid.exists) {
        deleted.users.push(authUid);
        if (byUid.data().companyId) companyIds.add(byUid.data().companyId);
        await byUid.ref.delete();
      }
    }
    deleted.candidates.push(
      ...(await deleteByQuery(db.collection('candidates').where('email', '==', email))),
    );
    for (const companyId of companyIds) {
      deleted.companies.push(companyId);
      deleted.vacancies.push(
        ...(await deleteByQuery(db.collection('vacancies').where('companyId', '==', companyId))),
      );
      const companyCandidates = await db
        .collection('candidates')
        .where('companyId', '==', companyId)
        .get();
      for (const doc of companyCandidates.docs) {
        deleted.candidates.push(doc.id);
        await db.collection('evaluations').doc(doc.id).delete().catch(() => {});
        await doc.ref.delete();
      }
      await deleteByQuery(
        db.collection('activation_invites').where('companyId', '==', companyId),
      );
      await db.collection('companies').doc(companyId).delete();
    }
    if (authUid) {
      await admin.auth().deleteUser(authUid);
    }
    return {ok: true, email, authUid, deleted};
  },
);

exports.purgeAllCompanies = onCall(
  {
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 120,
    invoker: 'public',
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Sign in required.');
    }
    const caller = await admin.firestore().collection('users').doc(request.auth.uid).get();
    if (caller.data()?.role !== 'superadmin') {
      throw new HttpsError('permission-denied', 'SuperAdmin required.');
    }
    const db = admin.firestore();
    const deleted = {
      companies: [],
      vacancies: [],
      candidates: [],
      invites: [],
      users: [],
    };
    const companies = await db.collection('companies').get();
    for (const company of companies.docs) {
      const companyId = company.id;
      deleted.companies.push(companyId);
      deleted.vacancies.push(
        ...(await deleteByQuery(db.collection('vacancies').where('companyId', '==', companyId))),
      );
      const companyCandidates = await db
        .collection('candidates')
        .where('companyId', '==', companyId)
        .get();
      for (const doc of companyCandidates.docs) {
        deleted.candidates.push(doc.id);
        await db.collection('evaluations').doc(doc.id).delete().catch(() => {});
        await doc.ref.delete();
      }
      deleted.invites.push(
        ...(await deleteByQuery(
          db.collection('activation_invites').where('companyId', '==', companyId),
        )),
      );
      await company.ref.delete();
    }
    const leftoverInvites = await db.collection('activation_invites').get();
    for (const doc of leftoverInvites.docs) {
      deleted.invites.push(doc.id);
      await doc.ref.delete();
    }
    const users = await db.collection('users').get();
    for (const doc of users.docs) {
      const data = doc.data() || {};
      if (data.role === 'superadmin') continue;
      const hadCompany = Boolean(data.companyId) ||
        data.role === 'company_admin' ||
        data.role === 'recruiter' ||
        data.role === 'respondent';
      if (!hadCompany) continue;
      deleted.users.push(doc.id);
      await doc.ref.delete();
      await admin.auth().deleteUser(doc.id).catch(() => {});
    }
    return {ok: true, deleted};
  },
);

const RESET_COOLDOWN_MS = 60 * 1000;
const RESET_HOUR_MS = 60 * 60 * 1000;
const RESET_MAX_HOUR = 5;
const RESET_MAX_ATTEMPTS = 5;
const RESET_PIN_TTL_MS = 15 * 60 * 1000;

const callablePublic = {
  region: 'us-central1',
  cors: true,
  timeoutSeconds: 60,
  invoker: 'public',
};

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function resetPinHash(email, pin) {
  return sha256(`talex-reset|${email}|${pin}`);
}

function resetTokenHash(token) {
  return sha256(`talex-reset-token|${token}`);
}

function isCompanyStaffRole(role) {
  return [
    'superadmin',
    'company_admin',
    'company_lead',
    'ceo',
    'people_ops',
    'hr',
    'recruiter',
    'hiring_manager',
  ].includes(String(role || ''));
}

async function customTokenForUsedInvite(db, invite) {
  const uid = String(invite.redeemedBy || '').trim();
  try {
    if (uid) {
      await admin.auth().getUser(uid);
      return {
        customToken: await admin.auth().createCustomToken(uid),
      };
    }
    const email = String(invite.email || '').trim().toLowerCase();
    const authUser = await admin.auth().getUserByEmail(email);
    const profile = await db.collection('users').doc(authUser.uid).get();
    const data = profile.data() || {};
    if (
      data.role === 'respondent' &&
      (!invite.candidateId || data.candidateId === invite.candidateId)
    ) {
      return {
        customToken: await admin.auth().createCustomToken(authUser.uid),
      };
    }
  } catch (error) {
    console.error('customTokenForUsedInvite error', error);
  }
  throw new HttpsError('failed-precondition', 'errorInviteUsed');
}

exports.redeemRespondentInvite = onCall(
  {
    region: 'us-central1',
    cors: true,
    timeoutSeconds: 60,
    invoker: 'public',
  },
  async (request) => {
    const token = String(request.data?.token || '').trim();

    if (!token) {
      throw new HttpsError(
        'invalid-argument',
        'errorInviteInvalid',
      );
    }

    const db = admin.firestore();
    const tokenHash = sha256(token);

    const snapshot = await db
      .collection('activation_invites')
      .where('tokenHash', '==', tokenHash)
      .limit(1)
      .get();

    if (snapshot.empty) {
      throw new HttpsError(
        'not-found',
        'errorInviteInvalid',
      );
    }

    const inviteDoc = snapshot.docs[0];
    const inviteRef = inviteDoc.ref;
    const invite = inviteDoc.data() || {};

    if (invite.kind !== 'respondent') {
      throw new HttpsError(
        'failed-precondition',
        'errorInviteInvalid',
      );
    }

    if (invite.used === true) {
      return customTokenForUsedInvite(db, invite);
    }

    const expiresAt = toMillis(invite.tokenExpiresAt);

    if (!expiresAt || expiresAt <= Date.now()) {
      throw new HttpsError(
        'failed-precondition',
        'errorInviteExpired',
      );
    }

    const email = String(invite.email || '')
      .trim()
      .toLowerCase();

    if (!email.includes('@')) {
      throw new HttpsError(
        'failed-precondition',
        'errorInviteInvalid',
      );
    }

    let authUser;

    try {
      authUser = await admin.auth().getUserByEmail(email);
    } catch (error) {
      if (error.code !== 'auth/user-not-found') {
        console.error('redeemRespondentInvite getUserByEmail error', error);
        throw new HttpsError(
          'internal',
          'errorUnexpected',
        );
      }

      authUser = await admin.auth().createUser({
        email,
        emailVerified: true,
        displayName: [
          invite.firstName,
          invite.lastName,
        ]
          .filter(Boolean)
          .join(' ')
          .trim() || undefined,
      });
    }

    const userRef = db
      .collection('users')
      .doc(authUser.uid);

    const existingUser = await userRef.get();
    const existingData = existingUser.data() || {};
    const existingRole = existingData.role;

    if (isCompanyStaffRole(existingRole)) {
      throw new HttpsError(
        'failed-precondition',
        'errorInviteInvalid',
      );
    }

    await db.runTransaction(async (transaction) => {
      const currentInviteSnapshot = await transaction.get(
        inviteRef,
      );

      if (!currentInviteSnapshot.exists) {
        throw new HttpsError(
          'not-found',
          'errorInviteInvalid',
        );
      }

      const currentInvite =
        currentInviteSnapshot.data() || {};

      if (currentInvite.used === true) {
        throw new HttpsError(
          'failed-precondition',
          'errorInviteUsed',
        );
      }

      const currentExpiresAt =
        toMillis(currentInvite.tokenExpiresAt);

      if (
        !currentExpiresAt ||
        currentExpiresAt <= Date.now()
      ) {
        throw new HttpsError(
          'failed-precondition',
          'errorInviteExpired',
        );
      }

      transaction.set(
        userRef,
        {
          uid: authUser.uid,
          role: 'respondent',
          companyId: currentInvite.companyId,
          candidateId: currentInvite.candidateId,
          documentNumber: currentInvite.documentNumber,
          mustChangePassword: false,
          mustReviewCompanyDna: false,
          isActive: true,
          displayName: [
            currentInvite.firstName,
            currentInvite.lastName,
          ]
            .filter(Boolean)
            .join(' ')
            .trim(),
          email,
          createdAt: existingUser.exists
            ? existingData.createdAt ||
              admin.firestore.FieldValue.serverTimestamp()
            : admin.firestore.FieldValue.serverTimestamp(),
          updatedAt:
            admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true},
      );

      transaction.update(
        inviteRef,
        {
          used: true,
          redeemedAt:
            admin.firestore.FieldValue.serverTimestamp(),
          redeemedBy: authUser.uid,
        },
      );
    });

    const customToken =
      await admin.auth().createCustomToken(
        authUser.uid,
      );

    try {
      const {linkRespondent} = require('./supabase_session');
      await linkRespondent(authUser.uid, tokenHash);
    } catch (error) {
      console.error('redeemRespondentInvite supabase link', error);
    }

    return {
      customToken,
    };
  },
);

function toMillis(value) {
  if (!value) return 0;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (typeof value === 'number') return value;
  return 0;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function antiEnumerateDelay() {
  await sleep(400 + crypto.randomInt(0, 301));
}

function assertResetRateLimit(data, now) {
  const lastSent = toMillis(data.lastSentAt);
  if (lastSent && now - lastSent < RESET_COOLDOWN_MS) {
    throw new HttpsError('resource-exhausted', 'resetCooldown');
  }
  let hourStart = toMillis(data.hourWindowStart);
  let hourCount = data.hourCount || 0;
  if (!hourStart || now - hourStart >= RESET_HOUR_MS) {
    hourStart = now;
    hourCount = 0;
  }
  if (hourCount >= RESET_MAX_HOUR) {
    throw new HttpsError('resource-exhausted', 'tooManyAttempts');
  }
  return {hourStart, hourCount};
}

exports.requestPasswordReset = onCall(callablePublic, async (request) => {
  await antiEnumerateDelay();
  const email = String(request.data?.email || '').trim().toLowerCase();
  if (!email.includes('@')) {
    throw new HttpsError('invalid-argument', 'invalidPin');
  }
  const locale = request.data?.locale === 'en' ? 'en' : 'es';
  const db = admin.firestore();
  let authUser = null;
  try {
    authUser = await admin.auth().getUserByEmail(email);
  } catch (_) {
    authUser = null;
  }
  if (!authUser) {
    throw new HttpsError('not-found', 'accountNotFound');
  }
  const profile = await db.collection('users').doc(authUser.uid).get();
  if (!profile.exists) {
    const byEmail = await db.collection('users').where('email', '==', email).limit(1).get();
    if (byEmail.empty) {
      throw new HttpsError('not-found', 'accountNotFound');
    }
  }
  const {host, user, pass, from, port} = smtpConfig();
  if (!host || !user || !pass) {
    throw new HttpsError('failed-precondition', 'SMTP is not configured.');
  }
  const ref = db.collection('password_resets').doc(email);
  const snap = await ref.get();
  const now = Date.now();
  const data = snap.data() || {};
  const {hourStart, hourCount} = assertResetRateLimit(data, now);
  const nextHour = {
    lastSentAt: admin.firestore.Timestamp.fromMillis(now),
    hourWindowStart: admin.firestore.Timestamp.fromMillis(hourStart),
    hourCount: hourCount + 1,
    email,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  const pin = String(crypto.randomInt(100000, 1000000));
  const pinHash = resetPinHash(email, pin);
  const expiresAt = admin.firestore.Timestamp.fromMillis(now + RESET_PIN_TTL_MS);
  const t = copy(locale, 'recovery_pin', 'recovery_pin');
  const appUrl = 'https://talex-platform.web.app';
  const images = brandImageUrls();
  try {
    await sendWithFallback({
      host,
      user,
      pass,
      from,
      preferredPort: port,
      mail: {
        from: `TaleX <${from}>`,
        to: email,
        subject: t.subject(),
        text: `${t.hello()}\n${t.intro()}\n${t.pinLabel}: ${pin}\n${t.pinTtl}\n${t.next}\n${appUrl}/recover`,
        html: html({
          locale,
          type: 'recovery_pin',
          situation: 'recovery_pin',
          firstName: '',
          companyName: '',
          vacancyName: '',
          pin,
          appUrl: `${appUrl}/recover`,
          images,
        }),
      },
    });
  } catch (error) {
    throw new HttpsError('internal', error.message || 'SMTP send failed.');
  }
  await ref.set(
    {
      ...nextHour,
      pinHash,
      expiresAt,
      attempts: 0,
      used: false,
      tokenHash: admin.firestore.FieldValue.delete(),
      tokenExpiresAt: admin.firestore.FieldValue.delete(),
    },
    {merge: true},
  );
  return {ok: true};
});

exports.verifyPasswordResetPin = onCall(callablePublic, async (request) => {
  await antiEnumerateDelay();
  const email = String(request.data?.email || '').trim().toLowerCase();
  const pin = String(request.data?.pin || '').trim();
  if (!email.includes('@') || pin.length !== 6) {
    throw new HttpsError('invalid-argument', 'invalidPin');
  }
  const db = admin.firestore();
  const ref = db.collection('password_resets').doc(email);
  const snap = await ref.get();
  const data = snap.data() || {};
  if (!snap.exists || data.used === true || !data.pinHash) {
    throw new HttpsError('not-found', 'invalidPin');
  }
  const now = Date.now();
  if (toMillis(data.expiresAt) <= now) {
    throw new HttpsError('failed-precondition', 'pinExpired');
  }
  const attempts = data.attempts || 0;
  if (attempts >= RESET_MAX_ATTEMPTS) {
    throw new HttpsError('resource-exhausted', 'tooManyAttempts');
  }
  if (data.pinHash !== resetPinHash(email, pin)) {
    await ref.update({attempts: attempts + 1});
    throw new HttpsError('invalid-argument', 'invalidPin');
  }
  const resetToken = crypto.randomBytes(32).toString('hex');
  await ref.update({
    pinHash: admin.firestore.FieldValue.delete(),
    tokenHash: resetTokenHash(resetToken),
    tokenExpiresAt: admin.firestore.Timestamp.fromMillis(now + RESET_PIN_TTL_MS),
    attempts: 0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {ok: true, resetToken};
});

exports.completePasswordReset = onCall(callablePublic, async (request) => {
  const email = String(request.data?.email || '').trim().toLowerCase();
  const resetToken = String(request.data?.resetToken || '').trim();
  const password = String(request.data?.password || '');
  if (!email.includes('@') || !resetToken) {
    throw new HttpsError('invalid-argument', 'invalidPin');
  }
  if (password.length < 6) {
    throw new HttpsError('invalid-argument', 'passwordTooShort');
  }
  const db = admin.firestore();
  const ref = db.collection('password_resets').doc(email);
  const snap = await ref.get();
  const data = snap.data() || {};
  if (!snap.exists || data.used === true || !data.tokenHash) {
    throw new HttpsError('not-found', 'invalidPin');
  }
  if (toMillis(data.tokenExpiresAt) <= Date.now()) {
    throw new HttpsError('failed-precondition', 'pinExpired');
  }
  if (data.tokenHash !== resetTokenHash(resetToken)) {
    throw new HttpsError('invalid-argument', 'invalidPin');
  }
  let authUser;
  try {
    authUser = await admin.auth().getUserByEmail(email);
  } catch (_) {
    throw new HttpsError('not-found', 'invalidPin');
  }
  try {
    await admin.auth().updateUser(authUser.uid, {password});
  } catch (error) {
    if (String(error.message || '').toLowerCase().includes('password')) {
      throw new HttpsError('invalid-argument', 'passwordTooShort');
    }
    throw new HttpsError('internal', error.message || 'Reset failed.');
  }
  const userDoc = db.collection('users').doc(authUser.uid);
  await userDoc.set(
    {
      mustChangePassword: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
  const extras = await db.collection('users').where('email', '==', email).get();
  for (const doc of extras.docs) {
    if (doc.id === authUser.uid) continue;
    await doc.ref.set(
      {
        mustChangePassword: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  }
  await ref.set(
    {
      used: true,
      pinHash: admin.firestore.FieldValue.delete(),
      tokenHash: admin.firestore.FieldValue.delete(),
      tokenExpiresAt: admin.firestore.FieldValue.delete(),
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true},
  );
  return {ok: true};
});

const affinity = require('./affinity');
exports.analyzeAffinityOnCompletion = affinity.analyzeAffinityOnCompletion;
exports.analyzeCandidateAffinity = affinity.analyzeCandidateAffinity;

const assistant = require('./assistant');
exports.askAssistant = assistant.askAssistant;

const supabaseSession = require('./supabase_session');
exports.mintSupabaseSession = supabaseSession.mintSupabaseSession;
exports.getSupabasePublicConfig = supabaseSession.getSupabasePublicConfig;

