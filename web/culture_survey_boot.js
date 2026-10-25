(function (global) {
  var match = String(location.pathname || '').match(/^\/cultura\/([^/]+)(\/informe)?\/?$/);
  if (!match) {
    global.TalexCultureBoot = {started: false};
    return;
  }

  global.TalexCultureBoot = {started: true};
  var orgId = match[1];
  var isReport = Boolean(match[2]);
  var API = 'https://api.talex.com.co';
  var LOGO = '/talex_logo_horizontal_fondo_oscuro.png';

  document.title = 'Diagnóstico cultural · TaleX';
  document.documentElement.lang = 'es';
  document.head.insertAdjacentHTML(
    'beforeend',
    '<meta name="viewport" content="width=device-width, initial-scale=1">' +
      '<style>' +
      ':root{color-scheme:light}*{box-sizing:border-box}' +
      'body{margin:0;min-height:100vh;background:#ffffff;color:#0b1528;font-family:Arial,Helvetica,sans-serif;-webkit-text-size-adjust:100%}' +
      '.top{background:#0b1528;border-bottom:3px solid #a4e765}' +
      '.top-inner{width:min(720px,92vw);margin:0 auto;padding:16px 0;display:flex;justify-content:space-between;align-items:center;gap:16px}' +
      '.top img{display:block;height:40px;width:auto}' +
      '.progress{font-size:13px;font-weight:700;color:#a4e765;letter-spacing:.04em}' +
      'main{width:min(720px,92vw);margin:0 auto;padding:36px 0 80px}' +
      '.eyebrow{margin:0 0 16px;font-size:12px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:#254a78}' +
      'h1{margin:0 0 16px;font-size:clamp(28px,5vw,36px);line-height:1.2;letter-spacing:-.6px;font-weight:700;color:#0b1528}' +
      '.lead{margin:0 0 16px;font-size:16px;line-height:1.7;color:#4b5563}' +
      '.card{margin-top:8px;background:#f3f6fa;border:1px solid #dce4ee;border-left:4px solid #254a78;border-radius:12px;padding:24px}' +
      '.section{margin:0 0 8px;font-size:12px;font-weight:700;letter-spacing:1.2px;text-transform:uppercase;color:#254a78}' +
      '.name{margin:0 0 10px;font-size:13px;color:#596779}' +
      '.statement{margin:0 0 12px;font-size:22px;line-height:1.4;font-weight:700;color:#0b1528}' +
      '.hint{margin:0 0 18px;font-size:14px;line-height:1.6;color:#596779}' +
      '.options{display:grid;gap:8px}' +
      '.opt{display:grid;grid-template-columns:1fr auto auto;gap:8px;align-items:center;padding:12px 14px;border:1px solid #dce4ee;background:#ffffff;border-radius:8px}' +
      '.opt.single{grid-template-columns:auto 1fr;cursor:pointer}' +
      '.opt.single:hover,.opt.active{border-color:#0b1528}' +
      '.chip{border:1px solid #dce4ee;background:#ffffff;color:#0b1528;font:700 12px/1 Arial,Helvetica,sans-serif;letter-spacing:.02em;padding:9px 12px;border-radius:8px;cursor:pointer}' +
      '.chip.on{background:#0b1528;color:#ffffff;border-color:#0b1528}' +
      '.chip.no.on{background:#254a78;border-color:#254a78}' +
      'textarea,input[type=number]{width:100%;border:1px solid #dce4ee;border-radius:8px;padding:12px 14px;font:16px/1.5 Arial,Helvetica,sans-serif;background:#ffffff;color:#0b1528}' +
      'textarea{min-height:110px}' +
      '.forecast{margin-top:18px}' +
      '.forecast label{display:block;font-size:14px;color:#4b5563;margin-bottom:8px}' +
      '.value-row{display:grid;gap:8px;padding:12px 0;border-bottom:1px solid #e7ebef}' +
      '.value-row:last-child{border-bottom:0}' +
      '.scale{display:flex;flex-wrap:wrap;gap:8px}' +
      '.actions{display:flex;justify-content:space-between;gap:12px;margin-top:22px}' +
      'button{border:0;cursor:pointer;font:700 14px/1 Arial,Helvetica,sans-serif;letter-spacing:.02em;padding:13px 20px;border-radius:8px}' +
      '.next{background:#0b1528;color:#ffffff}' +
      '.back{background:transparent;color:#254a78;padding-left:0}' +
      '.error{color:#b42318;margin-top:12px;font-size:14px}' +
      '.count{font-size:13px;color:#596779;margin:0 0 12px}' +
      '.note{margin:20px 0 0;font-size:13px;line-height:1.6;color:#596779}' +
      '@media (max-width:640px){.opt{grid-template-columns:1fr}.chip{width:100%}}' +
      '</style>',
  );

  var app;
  var progress;
  var survey = null;
  var index = -1;
  var answers = {};

  function escapeHtml(value) {
    return String(value || '').replace(/[&<>"']/g, function (ch) {
      return {'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[ch];
    });
  }

  function shell(body) {
    return (
      '<div class="top"><div class="top-inner">' +
        '<a href="https://talex.com.co"><img src="' + LOGO + '" alt="TaleX" width="120" height="40"></a>' +
        '<div class="progress" id="progress"></div>' +
      '</div></div><main id="app">' + body + '</main>'
    );
  }

  function current() {
    return survey.questions[index];
  }

  function answer(id) {
    return answers[id] || (answers[id] = {});
  }

  function card(title, body, action) {
    return (
      '<p class="eyebrow">Tu cultura · La voz de tu equipo</p>' +
      '<h1>' + escapeHtml(title) + '</h1>' +
      '<p class="lead">' + escapeHtml(body) + '</p>' +
      (action || '')
    );
  }

  function startScreen() {
    progress.textContent = '';
    app.innerHTML = card(
      'Descubre la cultura que vive tu equipo.',
      (survey.intro || 'Responde con calma. No hay respuestas correctas.') +
        (survey.organizationName ? ' Estás respondiendo para ' + survey.organizationName + '.' : ''),
      '<div class="card">' +
        '<h2 class="statement" style="font-size:18px">Tu respuesta es individual y anónima.</h2>' +
        '<p class="lead" style="margin:0 0 20px">No necesitas crear una cuenta. Las respuestas se agrupan para la empresa.</p>' +
        '<button class="next" type="button" id="start">Empezar diagnóstico</button>' +
      '</div>',
    );
    document.getElementById('start').onclick = function () {
      index = 0;
      render();
    };
  }

  async function load() {
    try {
      if (isReport) {
        var reportRes = await fetch(API + '/api/cultura/' + encodeURIComponent(orgId) + '/informe');
        var report = await reportRes.json();
        if (!reportRes.ok) throw new Error(report.message || 'El informe aún no está listo.');
        app.innerHTML = card(
          report.organizationName || 'Informe cultural',
          report.status === 'collecting'
            ? 'Cuando el equipo alcance el mínimo de participación, aquí estará la lectura cultural.'
            : 'Ya hay suficientes respuestas para armar el informe.',
        );
        return;
      }
      var response = await fetch(API + '/api/cultura/' + encodeURIComponent(orgId));
      survey = await response.json();
      if (!response.ok) throw new Error(survey.message || 'No encontramos este diagnóstico.');
      startScreen();
    } catch (error) {
      app.innerHTML = card('No pudimos abrir el diagnóstico', error.message);
    }
  }

  function bodyFor(q) {
    var a = answer(q.id);
    if (q.format === 'text') {
      return '<textarea id="text" maxlength="' + (q.maxLength || 280) + '">' + escapeHtml(a.value_text || '') + '</textarea>';
    }
    if (q.format === 'value_coherence') {
      return '<div>' + (q.items || []).map(function (item) {
        return '<div class="value-row"><strong>' + escapeHtml(item.label) + '</strong><div class="scale">' +
          (q.scale || []).map(function (opt) {
            return '<button class="chip' + (a.ratings && a.ratings[item.id] === opt.id ? ' on' : '') +
              '" type="button" data-item="' + item.id + '" data-value="' + opt.id + '">' + escapeHtml(opt.label) + '</button>';
          }).join('') + '</div></div>';
      }).join('') + '</div>';
    }
    if (q.format === 'pick_yes_no') {
      var yes = (a.yes || []).length;
      var no = (a.no || []).length;
      return '<p class="count">Sí: ' + yes + ' / ' + q.yesCount + ' · No espere: ' + no + ' / ' + q.noCount + '</p><div class="options">' +
        (q.options || []).map(function (opt) {
          return '<div class="opt"><span>' + escapeHtml(opt.label) + '</span>' +
            '<button class="chip' + ((a.yes || []).indexOf(opt.id) >= 0 ? ' on' : '') + '" type="button" data-kind="yes" data-id="' + opt.id + '">Sí</button>' +
            '<button class="chip no' + ((a.no || []).indexOf(opt.id) >= 0 ? ' on' : '') + '" type="button" data-kind="no" data-id="' + opt.id + '">No espere</button></div>';
        }).join('') + '</div>';
    }
    if (q.format === 'most_least') {
      return '<div class="options">' + (q.options || []).map(function (opt) {
        return '<div class="opt"><span>' + escapeHtml(opt.label) + '</span>' +
          '<button class="chip' + (a.most === opt.id ? ' on' : '') + '" type="button" data-kind="most" data-id="' + opt.id + '">Más probable</button>' +
          '<button class="chip no' + (a.least === opt.id ? ' on' : '') + '" type="button" data-kind="least" data-id="' + opt.id + '">Menos probable</button></div>';
      }).join('') + '</div>' + (q.askForecast
        ? '<div class="forecast"><label>' + escapeHtml(q.forecastPrompt) + '</label><input id="forecast" type="number" min="0" max="100" value="' + (a.forecast ?? '') + '"></div>'
        : '');
    }
    return '<div class="options">' + (q.options || []).map(function (opt) {
      return '<label class="opt single' + (a.value === opt.id ? ' active' : '') + '"><input type="radio" name="a" value="' + opt.id + '"' +
        (a.value === opt.id ? ' checked' : '') + '> <span>' + escapeHtml(opt.label) + '</span></label>';
    }).join('') + '</div>';
  }

  function bind(q) {
    if (q.format === 'value_coherence') {
      document.querySelectorAll('[data-item]').forEach(function (btn) {
        btn.onclick = function () {
          var next = answer(q.id);
          next.ratings = next.ratings || {};
          next.ratings[btn.dataset.item] = btn.dataset.value;
          render();
        };
      });
      return;
    }
    if (q.format === 'pick_yes_no') {
      document.querySelectorAll('[data-kind]').forEach(function (btn) {
        btn.onclick = function () {
          var next = answer(q.id);
          next.yes = next.yes || [];
          next.no = next.no || [];
          var id = btn.dataset.id;
          next.yes = next.yes.filter(function (item) { return item !== id; });
          next.no = next.no.filter(function (item) { return item !== id; });
          if (btn.dataset.kind === 'yes' && next.yes.length < q.yesCount) next.yes.push(id);
          if (btn.dataset.kind === 'no' && next.no.length < q.noCount) next.no.push(id);
          render();
        };
      });
      return;
    }
    if (q.format === 'most_least') {
      document.querySelectorAll('[data-kind]').forEach(function (btn) {
        btn.onclick = function () {
          var next = answer(q.id);
          var id = btn.dataset.id;
          if (btn.dataset.kind === 'most') {
            next.most = id;
            if (next.least === id) next.least = '';
          } else {
            next.least = id;
            if (next.most === id) next.most = '';
          }
          render();
        };
      });
      var forecast = document.getElementById('forecast');
      if (forecast) forecast.oninput = function () { answer(q.id).forecast = Number(forecast.value); };
      return;
    }
    document.querySelectorAll('input[name=a]').forEach(function (input) {
      input.onchange = function () {
        answer(q.id).value = input.value;
        render();
      };
    });
  }

  function collect(q) {
    if (q.format === 'text') answer(q.id).value_text = document.getElementById('text').value.trim();
    if (q.format === 'most_least' && q.askForecast) {
      var forecast = document.getElementById('forecast');
      answer(q.id).forecast = forecast && forecast.value !== '' ? Number(forecast.value) : null;
    }
    return answer(q.id);
  }

  function valid(q, a) {
    if (q.format === 'most_least') {
      if (!a.most || !a.least || a.most === a.least) return 'Marca una opción más probable y otra menos probable.';
      if (q.askForecast && (!Number.isInteger(a.forecast) || a.forecast < 0 || a.forecast > 100)) {
        return 'Indica un porcentaje entre 0 y 100.';
      }
      return '';
    }
    if (q.format === 'value_coherence') {
      var ratings = a.ratings || {};
      return (q.items || []).every(function (item) { return ratings[item.id]; }) ? '' : 'Califica cada valor.';
    }
    if (q.format === 'pick_yes_no') {
      return (a.yes || []).length === q.yesCount && (a.no || []).length === q.noCount
        ? '' : 'Marca 4 que sí y 3 que no esperes.';
    }
    if (q.format === 'text') return a.value_text ? '' : 'Completa la frase.';
    return a.value ? '' : 'Elige una opción.';
  }

  function thanks() {
    progress.textContent = '';
    app.innerHTML = card(
      'Gracias por tu tiempo.',
      'Tus respuestas ya quedan en el diagnóstico de esta empresa. Puedes cerrar esta página.',
    );
  }

  function render() {
    if (!survey.questions.length) {
      app.innerHTML = card('El diagnóstico aún no está publicado', 'El equipo TaleX está cargando las preguntas.');
      return;
    }
    if (index < 0) return startScreen();
    if (index >= survey.questions.length) return thanks();
    var q = current();
    progress.textContent = index + 1 + ' / ' + survey.questions.length;
    app.innerHTML =
      '<p class="eyebrow">Diagnóstico cultural</p>' +
      '<div class="card">' +
      '<p class="section">' + escapeHtml(q.sectionTitle || '') + '</p>' +
      '<p class="name">' + escapeHtml(q.name || '') + '</p>' +
      '<p class="statement">' + escapeHtml(q.statement) + '</p>' +
      (q.instruction ? '<p class="hint">' + escapeHtml(q.instruction) + '</p>' : '') +
      bodyFor(q) +
      '<div class="error" id="err"></div>' +
      '<div class="actions">' +
        '<button class="back" type="button" id="back"' + (index === 0 ? ' disabled' : '') + '>Anterior</button>' +
        '<button class="next" type="button" id="next">' + (index === survey.questions.length - 1 ? 'Enviar respuestas' : 'Continuar') + '</button>' +
      '</div></div>' +
      '<p class="note">Tus respuestas se agrupan para la empresa. No se muestran de forma individual.</p>';
    document.getElementById('back').onclick = function () {
      if (index > 0) {
        index -= 1;
        render();
      }
    };
    document.getElementById('next').onclick = next;
    bind(q);
  }

  async function next() {
    var q = current();
    var a = collect(q);
    var message = valid(q, a);
    var err = document.getElementById('err');
    if (message) {
      err.textContent = message;
      return;
    }
    if (index < survey.questions.length - 1) {
      index += 1;
      render();
      window.scrollTo(0, 0);
      return;
    }
    document.getElementById('next').disabled = true;
    try {
      var response = await fetch(API + '/api/cultura/' + encodeURIComponent(orgId), {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({answers: answers}),
      });
      var payload = await response.json();
      if (!response.ok) throw new Error(payload.message || 'No pudimos guardar las respuestas.');
      index = survey.questions.length;
      thanks();
    } catch (error) {
      err.textContent = error.message;
      document.getElementById('next').disabled = false;
    }
  }

  function mount() {
    document.body.innerHTML = shell('Cargando el diagnóstico…');
    app = document.getElementById('app');
    progress = document.getElementById('progress');
    load();
  }

  if (document.body) mount();
  else document.addEventListener('DOMContentLoaded', mount);
})(window);
