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

  document.title = 'Encuesta de cultura · TaleX';
  document.documentElement.lang = 'es';
  document.head.insertAdjacentHTML(
    'beforeend',
    '<link rel="preconnect" href="https://fonts.googleapis.com">' +
      '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>' +
      '<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@500;600&family=Source+Sans+3:wght@400;500;600&display=swap" rel="stylesheet">' +
      '<style>' +
      ':root{color-scheme:light}*{box-sizing:border-box}' +
      'body{margin:0;min-height:100vh;background:#f3efe6;color:#17202a;font-family:"Source Sans 3",Arial,sans-serif}' +
      'header{padding:28px 8vw 0;display:flex;justify-content:space-between;align-items:baseline;gap:16px}' +
      '.brand{letter-spacing:.18em;text-transform:uppercase;font-size:12px;color:#7a715f}' +
      '.progress{font-size:13px;color:#6b7280}' +
      'main{width:min(760px,92vw);margin:0 auto;padding:36px 0 80px}' +
      'h1{font-family:"Cormorant Garamond",Georgia,serif;font-size:clamp(36px,5vw,52px);font-weight:500;margin:0 0 12px}' +
      '.lead{font-size:18px;line-height:1.6;color:#3d4550;max-width:38em}' +
      '.card{margin-top:28px;background:#fff;border:1px solid #e4ddd0;padding:28px 28px 24px}' +
      '.section{font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:#8a6a32;margin:0 0 6px}' +
      '.name{font-size:13px;color:#7a715f;margin:0 0 10px}' +
      '.statement{font-size:24px;line-height:1.35;margin:0 0 14px;font-family:"Cormorant Garamond",Georgia,serif}' +
      '.hint{font-size:14px;color:#6b7280;margin:0 0 18px}' +
      '.options{display:grid;gap:8px}' +
      '.opt{display:grid;grid-template-columns:1fr auto auto;gap:8px;align-items:center;padding:12px 14px;border:1px solid #e4ddd0;background:#fbfaf6}' +
      '.opt.single{grid-template-columns:auto 1fr;cursor:pointer}' +
      '.opt.single:hover,.opt.active{border-color:#102033;background:#fff}' +
      '.chip{border:1px solid #d7d0c3;background:#fff;color:#102033;font:600 11px/1 "Source Sans 3",Arial,sans-serif;letter-spacing:.04em;padding:8px 10px;cursor:pointer}' +
      '.chip.on{background:#102033;color:#f7f2e8;border-color:#102033}' +
      '.chip.no.on{background:#8a6a32;border-color:#8a6a32}' +
      'textarea,input[type=number]{width:100%;border:1px solid #d7d0c3;padding:12px 14px;font:16px/1.5 "Source Sans 3",Arial,sans-serif;background:#fbfaf6}' +
      'textarea{min-height:110px}' +
      '.forecast{margin-top:18px}' +
      '.forecast label{display:block;font-size:14px;color:#3d4550;margin-bottom:8px}' +
      '.value-row{display:grid;gap:8px;padding:12px 0;border-bottom:1px solid #efe8dc}' +
      '.scale{display:flex;flex-wrap:wrap;gap:8px}' +
      '.actions{display:flex;justify-content:space-between;gap:12px;margin-top:22px}' +
      'button{border:0;cursor:pointer;font:600 14px/1 "Source Sans 3",Arial,sans-serif;letter-spacing:.04em;padding:13px 20px}' +
      '.next{background:#102033;color:#f7f2e8}' +
      '.back{background:transparent;color:#102033;padding-left:0}' +
      '.error{color:#8a2b2b;margin-top:12px}' +
      '.count{font-size:13px;color:#6b7280;margin:0 0 12px}' +
      '@media (max-width:640px){.opt{grid-template-columns:1fr}.chip{width:100%}}' +
      '</style>',
  );

  document.body.innerHTML =
    '<header><div class="brand">TaleX · Encuesta de cultura</div><div class="progress" id="progress"></div></header>' +
    '<main id="app">Cargando…</main>';

  var app = document.getElementById('app');
  var progress = document.getElementById('progress');
  var survey = null;
  var index = 0;
  var answers = {};

  function escapeHtml(value) {
    return String(value || '').replace(/[&<>"']/g, function (ch) {
      return {'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[ch];
    });
  }

  function current() {
    return survey.questions[index];
  }

  function answer(id) {
    return answers[id] || (answers[id] = {});
  }

  function card(title, body) {
    return '<div class="card"><p class="section">TaleX</p><h1>' + escapeHtml(title) + '</h1><p class="lead">' + escapeHtml(body) + '</p></div>';
  }

  async function load() {
    try {
      if (isReport) {
        var reportRes = await fetch(API + '/api/cultura/' + encodeURIComponent(orgId) + '/informe');
        var report = await reportRes.json();
        if (!reportRes.ok) throw new Error(report.message || 'El informe aún no está listo.');
        app.innerHTML = card(report.title || 'Informe cultural', report.message || 'El informe se publicará cuando haya suficientes respuestas.');
        return;
      }
      var response = await fetch(API + '/api/cultura/' + encodeURIComponent(orgId));
      survey = await response.json();
      if (!response.ok) throw new Error(survey.message || 'No encontramos este diagnóstico.');
      render();
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
      if (!a.most || !a.least || a.most === a.least) return 'Marque una opción más probable y otra menos probable.';
      if (q.askForecast && (!Number.isInteger(a.forecast) || a.forecast < 0 || a.forecast > 100)) {
        return 'Indique un porcentaje entre 0 y 100.';
      }
      return '';
    }
    if (q.format === 'value_coherence') {
      var ratings = a.ratings || {};
      return (q.items || []).every(function (item) { return ratings[item.id]; }) ? '' : 'Califique cada valor.';
    }
    if (q.format === 'pick_yes_no') {
      return (a.yes || []).length === q.yesCount && (a.no || []).length === q.noCount
        ? '' : 'Marque 4 que sí y 3 que no espere.';
    }
    if (q.format === 'text') return a.value_text ? '' : 'Complete la frase.';
    return a.value ? '' : 'Elija una opción.';
  }

  function thanks() {
    progress.textContent = '';
    app.innerHTML = card('Gracias por su tiempo', 'Sus respuestas ya quedan en el diagnóstico de esta empresa. Puede cerrar esta página.');
  }

  function render() {
    if (!survey.questions.length) {
      app.innerHTML = card('El diagnóstico aún no está publicado', 'El equipo TaleX está cargando las preguntas.');
      return;
    }
    if (index >= survey.questions.length) return thanks();
    var q = current();
    progress.textContent = index + 1 + ' / ' + survey.questions.length;
    app.innerHTML =
      '<p class="lead" style="margin:0 0 8px">' + escapeHtml(index === 0 ? survey.intro : '') + '</p>' +
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
      '</div></div>';
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

  load();
})(window);
