(function (global) {
  var match = String(location.pathname || '').match(/^\/cultura\/([^/]+)(\/informe)?\/?$/);
  if (!match) {
    global.TalexCultureBoot = {started: false};
    return;
  }

  global.TalexCultureBoot = {started: true};
  var orgId = match[1];
  var isReport = Boolean(match[2]);
  // ?demo=1: vista previa para el equipo TaleX. Se ve y se comporta igual que
  // la encuesta real; la única diferencia es que al final no envía nada.
  var isDemo = !isReport && /(?:^|[?&])demo=(?:1|true)(?:&|$)/.test(String(location.search || ''));
  var isPreview = isDemo && orgId === 'preview';
  var API = 'https://api.talex.com.co';
  var LOGO = '/talex_logo_horizontal_trimmed.png';

  document.title = 'Diagnóstico cultural · TaleX';
  document.documentElement.lang = 'es';
  var themeColor = document.querySelector('meta[name="theme-color"]');
  if (themeColor) themeColor.content = '#ffffff';
  document.head.insertAdjacentHTML(
    'beforeend',
    '<meta name="viewport" content="width=device-width, initial-scale=1">' +
      '<link rel="preconnect" href="https://fonts.googleapis.com">' +
      '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>' +
      '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Atkinson+Hyperlegible+Next:wght@400..700&display=swap">' +
      '<style>' +
      ':root{color-scheme:light;--ink:#0b1528;--text:#2b3445;--muted:#5a6578;--faint:#8b95a5;--line:#dde3ea;--edge:#b9c3cf;--soft:#f1f3f6;--soft-2:#e6eaf0;--lime:#a4e765;--lime-ink:#3b6d11;--lime-soft:#eef8e2;--amber:#f2b33d;--blue:#2f64d0;--danger:#b42318;--font:"Atkinson Hyperlegible Next",system-ui,-apple-system,"Segoe UI",sans-serif}' +
      '*{box-sizing:border-box}' +
      'html{background:#ffffff}' +
      'body{margin:0;min-height:100vh;background:#ffffff;color:var(--ink);font:400 17px/1.55 var(--font);-webkit-text-size-adjust:100%;-webkit-font-smoothing:antialiased}' +
      ':focus-visible{outline:3px solid var(--blue);outline-offset:2px}' +
      '.top-inner{width:min(620px,calc(100% - 32px));margin:0 auto;padding:20px 0 16px;display:flex;justify-content:space-between;align-items:center;gap:16px}' +
      '.top img{display:block;height:26px;width:auto}' +
      '.progress{font-size:15px;color:var(--muted);font-variant-numeric:tabular-nums}' +
      '.bar{height:4px;background:var(--soft)}' +
      '.bar i{display:block;height:100%;width:0;background:var(--lime);transition:width .45s cubic-bezier(.2,.7,.2,1)}' +
      'main{width:min(620px,calc(100% - 32px));margin:0 auto;padding:56px 0 96px;color:var(--muted)}' +
      'h1{margin:0 0 20px;font-size:clamp(32px,6vw,42px);line-height:1.12;letter-spacing:-.015em;font-weight:700;color:var(--ink);text-wrap:balance}' +
      '.lead{margin:0 0 12px;max-width:32em;font-size:19px;line-height:1.6;color:var(--text)}' +
      '.meta{margin:0 0 36px;font-size:16px;color:var(--muted)}' +
      '.section{margin:0 0 10px;font-size:16px;color:var(--muted)}' +
      '.name{display:none}' +
      '.statement{margin:0 0 28px;font-size:clamp(24px,4.6vw,29px);line-height:1.28;letter-spacing:-.01em;font-weight:700;color:var(--ink);text-wrap:pretty}' +
      '.hint{margin:-16px 0 28px;font-size:17px;line-height:1.55;color:var(--muted)}' +
      '.options{display:grid;gap:6px}' +
      '.opt{display:grid;grid-template-columns:1fr auto auto;gap:8px;align-items:center;padding:16px 18px;background:var(--soft);border-radius:10px;color:var(--ink)}' +
      '.opt.single{grid-template-columns:auto 1fr;gap:14px;cursor:pointer;line-height:1.4;transition:background .12s}' +
      '.opt.single:hover{background:var(--soft-2)}' +
      '.opt input{-webkit-appearance:none;appearance:none;margin:0;width:22px;height:22px;border:2px solid var(--edge);border-radius:50%;background:#ffffff;cursor:pointer}' +
      '.opt input:checked{border-color:var(--ink);background:var(--ink);box-shadow:inset 0 0 0 5px #ffffff}' +
      '.opt.active,.opt.active:hover{background:var(--lime);font-weight:700}' +
      '.opt.active input{border-color:var(--ink)}' +
      'textarea,input[type=number]{width:100%;border:2px solid transparent;border-radius:10px;padding:16px 18px;font:400 17px/1.5 var(--font);background:var(--soft);color:var(--ink);transition:border-color .12s,background .12s}' +
      'textarea{min-height:150px;resize:vertical}' +
      'textarea:focus,input[type=number]:focus{outline:none;border-color:var(--ink);background:#ffffff}' +
      '.zones{position:sticky;top:0;z-index:2;display:grid;grid-template-columns:1fr 1fr;gap:8px;padding:12px 0;margin:-12px 0 10px;background:#ffffff}' +
      '.zone{min-height:96px;border:2px solid transparent;border-radius:10px;background:var(--soft);padding:12px 14px;transition:border-color .12s,background .12s;cursor:default;outline:none}' +
      '.zone.pos{background:var(--lime-soft)}' +
      '.zone:focus-visible{outline:3px solid var(--blue);outline-offset:2px}' +
      '.zone-head{display:flex;justify-content:space-between;align-items:baseline;gap:8px;margin-bottom:4px}' +
      '.zone-title{font-size:17px;font-weight:700}' +
      '.zone-count{font-size:15px;color:var(--muted);font-variant-numeric:tabular-nums}' +
      '.zone.pos .zone-title{color:var(--lime-ink)}.zone.neg .zone-title{color:var(--ink)}' +
      '.zone-empty{display:block;font-size:15px;color:var(--muted);padding:4px 0}' +
      '.zone.armed,body.is-dragging .zone{cursor:pointer;border-color:var(--ink);border-style:dashed}' +
      '.zone.over,body.is-dragging .zone.over{border-style:solid;border-color:var(--ink);background:#ffffff}' +
      '.placed{display:flex;align-items:center;gap:8px;padding:8px 6px 8px 12px;margin-top:6px;border-radius:8px;background:#ffffff;color:var(--ink);font-size:16px;line-height:1.35;font-weight:700}' +
      '.placed span{flex:1}' +
      '.unplace{flex:none;width:30px;height:30px;padding:0;border-radius:50%;background:transparent;color:var(--muted);font-size:20px;line-height:30px}' +
      '.unplace:hover{background:var(--soft);color:var(--ink)}' +
      '.pool{display:grid;gap:6px}' +
      '.dcard{display:flex;align-items:center;gap:12px;width:100%;text-align:left;padding:16px 18px 16px 12px;border:0;border-radius:10px;background:var(--soft);color:var(--ink);font:400 17px/1.4 var(--font);cursor:grab;touch-action:pan-y;user-select:none;-webkit-user-select:none;transition:background .12s,opacity .12s}' +
      '.dcard:hover{background:var(--soft-2)}' +
      '.dcard.picked{background:#ffffff;box-shadow:inset 0 0 0 2px var(--ink);font-weight:700}' +
      '.dcard.dragging{opacity:.3}' +
      '.grip{flex:none;display:grid;grid-template-columns:repeat(2,4px);gap:3px;padding:6px;touch-action:none;cursor:grab}' +
      '.grip i{width:4px;height:4px;border-radius:50%;background:var(--faint)}' +
      '.ghost{position:fixed;left:0;top:0;z-index:50;pointer-events:none;margin:0;max-width:min(520px,86vw);background:#ffffff;box-shadow:inset 0 0 0 2px var(--ink),0 12px 32px rgba(11,21,40,.16);will-change:transform}' +
      'body.is-dragging,body.is-dragging *{cursor:grabbing!important;user-select:none;-webkit-user-select:none}' +
      '.forecast{margin-top:40px}' +
      '.forecast-q{margin:0 0 6px;font-size:20px;line-height:1.4;color:var(--ink);font-weight:700}' +
      '.forecast-pick{display:block;margin:0 0 20px;font-size:16px;color:var(--muted)}' +
      '.forecast-row{display:flex;flex-direction:column;gap:16px;padding:0 2px}' +
      '.forecast-out{display:block;min-height:48px;font-size:44px;line-height:48px;font-weight:700;color:var(--ink);font-variant-numeric:tabular-nums}' +
      '.forecast.unset .forecast-out{font-size:17px;font-weight:400;color:var(--muted)}' +
      'input[type=range]{width:100%;-webkit-appearance:none;appearance:none;height:12px;border-radius:999px;background:linear-gradient(90deg,var(--lime) var(--p,0%),var(--soft-2) var(--p,0%));margin:0;cursor:pointer}' +
      '.forecast.unset input[type=range]{background:var(--soft-2)}' +
      'input[type=range]::-webkit-slider-thumb{-webkit-appearance:none;width:32px;height:32px;border-radius:50%;background:#ffffff;border:3px solid var(--ink);box-shadow:0 2px 6px rgba(11,21,40,.18);cursor:grab}' +
      'input[type=range]::-moz-range-thumb{width:26px;height:26px;border-radius:50%;background:#ffffff;border:3px solid var(--ink);box-shadow:0 2px 6px rgba(11,21,40,.18);cursor:grab}' +
      'input[type=range]:active::-webkit-slider-thumb{cursor:grabbing}' +
      '.forecast-scale{display:flex;justify-content:space-between;margin-top:16px;font-size:14px;color:var(--muted)}' +
      '.values{display:grid}' +
      '.value-card{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,360px);align-items:center;gap:12px 20px;padding:16px 0;border-top:1px solid var(--line)}' +
      '.value-card:last-child{border-bottom:1px solid var(--line)}' +
      '.value-name{margin:0;font-size:19px;font-weight:700;color:var(--ink)}' +
      '.tiles{display:grid;grid-template-columns:repeat(3,1fr);gap:3px;padding:3px;border-radius:10px;background:var(--soft)}' +
      '.tile{display:flex;align-items:center;justify-content:center;min-height:44px;padding:8px 6px;border:0;border-radius:8px;background:transparent;color:var(--text);font:400 15px/1.2 var(--font);text-align:center;transition:background .12s}' +
      '.tile:hover{background:var(--soft-2)}' +
      '.tile svg{display:none}' +
      '.tile.on{font-weight:700;color:var(--ink)}' +
      '.tile.k-vive.on{background:var(--lime)}' +
      '.tile.k-medias.on{background:var(--amber)}' +
      '.tile.k-pared.on{background:var(--ink);color:#ffffff}' +
      '.tile.on span{color:inherit}' +
      '.values-count{margin:0 0 8px;font-size:16px;color:var(--muted)}' +
      '.fill{display:flex;flex-wrap:wrap;align-items:baseline;gap:14px 8px;margin:0;font-size:24px;line-height:1.6;font-weight:400;color:var(--ink)}' +
      '.blank{flex:1 1 220px;min-width:0;border:0;border-bottom:2px solid var(--edge);border-radius:0;padding:4px 2px;background:transparent;font:700 22px/1.4 var(--font);color:var(--ink);outline:none;transition:border-color .12s,background .12s}' +
      '.blank:not(:placeholder-shown){border-bottom-color:var(--lime);border-bottom-width:4px}' +
      '.blank:focus{border-bottom-color:var(--ink);background:var(--soft)}' +
      '.blank::placeholder{color:var(--faint);font-weight:400}' +
      '.actions{display:flex;justify-content:space-between;align-items:center;gap:12px;margin-top:40px}' +
      'button{border:0;cursor:pointer;font:700 17px/1 var(--font);padding:17px 28px;border-radius:10px}' +
      '.next{min-width:180px;background:var(--ink);color:#ffffff;transition:background .12s}' +
      '.next:hover{background:#22314d}' +
      '.next:disabled{opacity:.55;cursor:progress}' +
      '.back{background:transparent;color:var(--muted);padding-left:0;padding-right:0;font-weight:400;text-decoration:underline;text-underline-offset:4px;text-decoration-color:var(--edge)}' +
      '.back:hover{color:var(--ink);text-decoration-color:var(--ink)}' +
      '.back:disabled{visibility:hidden}' +
      '.error{margin-top:16px;color:var(--danger);font-size:16px;font-weight:700}' +
      '.error:empty{margin:0}' +
      '@media (max-width:640px){body{font-size:16px}main{padding:32px 0 24px}.top-inner{padding:16px 0 12px}.top img{height:22px}.opt{grid-template-columns:1fr}.zone{min-height:84px}.value-card{grid-template-columns:1fr}.fill{font-size:20px}.blank{font-size:19px}.actions{position:sticky;bottom:0;z-index:3;margin:28px -16px 0;padding:12px 16px calc(12px + env(safe-area-inset-bottom));background:#ffffff;border-top:1px solid var(--line)}.next{flex:1}.back:disabled{display:none}}' +
      '@media (prefers-reduced-motion:reduce){*{transition:none!important}}' +
      '</style>',
  );

  var app;
  var progress;
  var bar;
  var survey = null;
  var index = -1;
  var answers = {};
  // Textos de cada espacio en "completa la frase" (se envían unidos).
  var fills = {};
  // Opción tocada que espera una casilla (modo tocar en lugar de arrastrar).
  var picked = null;
  var pickedFor = -1;
  var drag = null;
  var justDragged = false;
  var touchFirst = Boolean(global.matchMedia && global.matchMedia('(pointer: coarse)').matches);

  function escapeHtml(value) {
    return String(value || '').replace(/[&<>"']/g, function (ch) {
      return {'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[ch];
    });
  }

  function shell(body) {
    return (
      '<div class="top"><div class="top-inner">' +
        '<a href="https://talex.com.co"><img src="' + LOGO + '" alt="TaleX" width="90" height="28"></a>' +
        '<div class="progress" id="progress" aria-live="polite"></div>' +
      '</div></div><div class="bar" aria-hidden="true"><i id="bar"></i></div><main id="app">' + body + '</main>'
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
      '<h1>' + escapeHtml(title) + '</h1>' +
      '<p class="lead">' + escapeHtml(body) + '</p>' +
      (action || '')
    );
  }

  // Texto "3 de 14" y barra superior.
  function setProgress(step, total) {
    progress.textContent = step && step <= total ? step + ' de ' + total : '';
    bar.style.width = total ? Math.min(100, Math.round((step / total) * 100)) + '%' : '0';
  }

  function startScreen() {
    setProgress(0, 0);
    var total = survey.questions.length;
    app.innerHTML = card(
      survey.title || 'Diagnóstico cultural',
      survey.intro || 'Responde con calma. No hay respuestas correctas.',
      (total
        ? '<p class="meta">Son ' + total + (total === 1 ? ' pregunta' : ' preguntas') +
          '. Puedes volver atrás cuando quieras.</p>'
        : '') +
      '<button class="next" type="button" id="start">Empezar</button>',
    );
    document.getElementById('start').onclick = function () {
      index = 0;
      render();
    };
  }

  // /cultura/preview?demo=1: el admin deja el banco activo en localStorage
  // (CultureSurveyLink.previewStorageKey) y aquí se arma la encuesta como lo
  // hace el backend, pero sin empresa: las listas dinámicas usan sus opciones
  // por defecto (fallback_options).
  function previewSurvey() {
    var raw = null;
    try {
      raw = JSON.parse(localStorage.getItem('talex.cultureSurveyPreview') || 'null');
    } catch (_) {}
    if (!raw) throw new Error('Abre la vista previa desde el panel de administración.');
    var copy = raw.survey || {};
    var rows = (raw.questions || [])
      .filter(function (row) { return row && row.kind !== 'survey' && row.is_active !== false; })
      .sort(function (a, b) { return (a.sort_order || 0) - (b.sort_order || 0); });
    return {
      title: copy.title || 'Encuesta de cultura para empleados',
      intro: copy.intro || 'Responda con calma. No hay respuestas correctas: nos interesa cómo se vive el trabajo en su organización.',
      questions: rows.map(function (row) {
        var source = row.options_source || 'static';
        var fallback = row.fallback_options || [];
        return {
          id: row.code,
          code: row.code,
          section: row.section,
          sectionTitle: row.section_title,
          name: row.name,
          technique: row.technique,
          statement: row.statement,
          instruction: row.instruction,
          format: row.format,
          options: previewItems(source === 'organization_areas' ? fallback : row.options),
          required: row.required !== false,
          askForecast: Boolean(row.ask_forecast),
          forecastPrompt: row.forecast_prompt || '',
          items: previewItems(source === 'declared_values' ? fallback : row.items),
          scale: row.scale || [],
          yesCount: row.yes_count == null ? null : row.yes_count,
          noCount: row.no_count == null ? null : row.no_count,
          maxLength: row.max_length == null ? null : row.max_length,
        };
      }),
    };
  }

  function previewItems(values) {
    var seen = {};
    var next = [];
    (values || []).forEach(function (raw) {
      var label = String((raw && (raw.label || raw.name)) || raw || '').trim();
      if (!label || seen[label.toLowerCase()]) return;
      seen[label.toLowerCase()] = true;
      next.push({id: String((raw && raw.id) || 'v' + (next.length + 1)), label: label, dimension: (raw && raw.dimension) || null});
    });
    return next;
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
      if (isPreview) {
        survey = previewSurvey();
        startScreen();
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

  var ICONS = {
    vive: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    medias: '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="8" fill="none" stroke="currentColor" stroke-width="2.2"/><path d="M12 4a8 8 0 0 1 0 16z" fill="currentColor"/></svg>',
    pared: '<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="3.2" r="1.3" fill="currentColor"/><path d="M12 3.5L7 9M12 3.5L17 9" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><rect x="4" y="9" width="16" height="12" rx="1.5" fill="none" stroke="currentColor" stroke-width="2"/></svg>',
  };

  // Tipo visual de cada punto de la escala: por puntaje y, si no hay, por posición.
  function scaleKind(q, opt) {
    var score = Number(opt.score);
    if (!isNaN(score) && opt.score !== null && opt.score !== undefined) {
      return score >= 1 ? 'vive' : score > 0 ? 'medias' : 'pared';
    }
    return ['vive', 'medias', 'pared'][(q.scale || []).indexOf(opt)] || 'medias';
  }

  // Casillas de las preguntas de arrastrar.
  function zonesFor(q) {
    if (q.format === 'most_least') {
      return [
        {key: 'most', label: 'Más probable', cap: 1, tone: 'pos'},
        {key: 'least', label: 'Menos probable', cap: 1, tone: 'neg'},
      ];
    }
    return [
      {key: 'yes', label: 'Sí', cap: q.yesCount || 0, tone: 'pos'},
      {key: 'no', label: 'No', cap: q.noCount || 0, tone: 'neg'},
    ];
  }

  function placedIn(q, a, key) {
    if (q.format === 'most_least') return a[key] ? [a[key]] : [];
    return (a[key] || []).slice();
  }

  function setPlaced(q, a, key, list) {
    if (q.format === 'most_least') a[key] = list[0] || '';
    else a[key] = list;
  }

  function optionLabel(q, id) {
    var found = (q.options || []).filter(function (opt) { return opt.id === id; })[0];
    return found ? found.label : '';
  }

  function showError(message) {
    var err = document.getElementById('err');
    if (err) err.textContent = message;
  }

  function place(q, id, key) {
    var a = answer(q.id);
    var zone = zonesFor(q).filter(function (z) { return z.key === key; })[0];
    var target = placedIn(q, a, key).filter(function (item) { return item !== id; });
    if (target.length >= zone.cap && zone.cap > 1) {
      showError('Ya pusiste ' + zone.cap + ' en «' + zone.label + '». Quita una para cambiarla.');
      return;
    }
    zonesFor(q).forEach(function (z) {
      setPlaced(q, a, z.key, placedIn(q, a, z.key).filter(function (item) { return item !== id; }));
    });
    if (zone.cap === 1) target = [];
    target.push(id);
    setPlaced(q, a, key, target);
    picked = null;
    render();
  }

  function unplace(q, id) {
    var a = answer(q.id);
    zonesFor(q).forEach(function (z) {
      setPlaced(q, a, z.key, placedIn(q, a, z.key).filter(function (item) { return item !== id; }));
    });
    render();
  }

  function dndBody(q, a) {
    var placedIds = [];
    var zones = zonesFor(q).map(function (z) {
      var list = placedIn(q, a, z.key);
      placedIds = placedIds.concat(list);
      var full = list.length >= z.cap;
      return '<div class="zone ' + z.tone + (full ? ' full' : '') + (picked ? ' armed' : '') +
        '" data-zone="' + z.key + '" role="button" tabindex="0" aria-label="' + escapeHtml(z.label) + '">' +
        '<div class="zone-head"><span class="zone-title">' + escapeHtml(z.label) + '</span>' +
        (z.cap > 1 ? '<span class="zone-count">' + list.length + ' / ' + z.cap + '</span>' : '') + '</div>' +
        (list.length
          ? list.map(function (id) {
              return '<div class="placed"><span>' + escapeHtml(optionLabel(q, id)) + '</span>' +
                '<button class="unplace" type="button" data-unplace="' + escapeHtml(id) + '" aria-label="Quitar">×</button></div>';
            }).join('')
          : '<span class="zone-empty">' + (picked ? 'Toca para ponerla aquí' : touchFirst ? 'Toca una opción y luego aquí' : 'Arrastra una opción aquí') + '</span>') +
        '</div>';
    }).join('');
    var pool = (q.options || []).filter(function (opt) { return placedIds.indexOf(opt.id) < 0; }).map(function (opt) {
      return '<button class="dcard' + (picked === opt.id ? ' picked' : '') + '" type="button" data-id="' + escapeHtml(opt.id) + '">' +
        '<span class="grip" aria-hidden="true"><i></i><i></i><i></i><i></i><i></i><i></i></span>' +
        '<span>' + escapeHtml(opt.label) + '</span></button>';
    }).join('');
    return '<div class="zones">' + zones + '</div><div class="pool">' + pool + '</div>';
  }

  function forecastBody(q, a) {
    var set = Number.isInteger(a.forecast);
    var value = set ? a.forecast : 0;
    var prompt = String(q.forecastPrompt || '').replace(/\s*\(\s*0\s*a\s*100\s*%?\s*\)\s*$/i, '');
    return '<div class="forecast' + (set ? '' : ' unset') + '" id="forecast-box">' +
      '<p class="forecast-q">' + escapeHtml(prompt) + '</p>' +
      (a.most ? '<span class="forecast-pick">Tu más probable: «' + escapeHtml(optionLabel(q, a.most)) + '»</span>' : '') +
      '<div class="forecast-row">' +
        '<output class="forecast-out" id="forecast-out" for="forecast">' + (set ? value + ' %' : 'Mueve el punto hacia la derecha') + '</output>' +
        '<input id="forecast" type="range" min="0" max="100" step="5" value="' + value + '" style="--p:' + value + '%" aria-label="Porcentaje de compañeros">' +
      '</div>' +
      '<div class="forecast-scale" aria-hidden="true"><span>Nadie</span><span>La mitad</span><span>Todos</span></div>' +
    '</div>';
  }

  // "Complete la frase: «Aquí le va bien al que… y le va mal al que…»" →
  // {lead: 'Complete la frase', pieces: ['Aquí le va bien al que', ' y le va mal al que', '']}.
  function phraseOf(q) {
    var m = String(q.statement || '').match(/«([^»]+)»/);
    if (!m) return null;
    var pieces = m[1].split(/…|\.\.\./);
    if (pieces.length < 2) return null;
    var lead = String(q.statement).replace(m[0], '').replace(/[\s:]+$/, '').trim();
    return {lead: lead, pieces: pieces};
  }

  function fillParts(q, phrase) {
    var count = phrase.pieces.length - 1;
    if (!fills[q.id]) {
      var saved = String(answer(q.id).value_text || '');
      var parts = saved ? saved.split(', ') : [];
      if (parts.length > count) parts = parts.slice(0, count - 1).concat(parts.slice(count - 1).join(', '));
      fills[q.id] = [];
      for (var i = 0; i < count; i++) fills[q.id].push(parts[i] || '');
    }
    return fills[q.id];
  }

  function fillBody(q, phrase) {
    var parts = fillParts(q, phrase);
    var max = Math.max(20, Math.floor(((q.maxLength || 280) - 2 * (parts.length - 1)) / parts.length));
    var html = '';
    phrase.pieces.forEach(function (piece, i) {
      if (piece.trim()) html += '<span>' + escapeHtml(piece.trim()) + '</span>';
      if (i < parts.length) {
        html += '<input class="blank" type="text" data-blank="' + i + '" maxlength="' + max + '" placeholder="escribe aquí" value="' + escapeHtml(parts[i]) + '">';
      }
    });
    return '<p class="fill">' + html + '</p>';
  }

  function bodyFor(q) {
    var a = answer(q.id);
    if (q.format === 'text') {
      var phrase = phraseOf(q);
      if (phrase) return fillBody(q, phrase);
      return '<textarea id="text" maxlength="' + (q.maxLength || 280) + '">' + escapeHtml(a.value_text || '') + '</textarea>';
    }
    if (q.format === 'value_coherence') {
      var items = q.items || [];
      var ratings = a.ratings || {};
      var done = items.filter(function (item) { return ratings[item.id]; }).length;
      return (items.length > 1 ? '<p class="values-count">' + done + ' de ' + items.length + ' valores</p>' : '') +
        '<div class="values">' + items.map(function (item) {
          var chosen = (q.scale || []).filter(function (opt) { return opt.id === ratings[item.id]; })[0];
          return '<div class="value-card' + (chosen ? ' k-' + scaleKind(q, chosen) : '') + '">' +
            '<p class="value-name">' + escapeHtml(item.label) + '</p><div class="tiles">' +
            (q.scale || []).map(function (opt) {
              var kind = scaleKind(q, opt);
              var on = ratings[item.id] === opt.id;
              return '<button class="tile k-' + kind + (on ? ' on' : '') + '" type="button" aria-pressed="' + on +
                '" data-item="' + escapeHtml(item.id) + '" data-value="' + escapeHtml(opt.id) + '">' +
                ICONS[kind] + '<span>' + escapeHtml(opt.label) + '</span></button>';
            }).join('') + '</div></div>';
        }).join('') + '</div>';
    }
    if (q.format === 'pick_yes_no') return dndBody(q, a);
    if (q.format === 'most_least') return dndBody(q, a) + (q.askForecast ? forecastBody(q, a) : '');
    return '<div class="options">' + (q.options || []).map(function (opt) {
      return '<label class="opt single' + (a.value === opt.id ? ' active' : '') + '"><input type="radio" name="a" value="' + opt.id + '"' +
        (a.value === opt.id ? ' checked' : '') + '> <span>' + escapeHtml(opt.label) + '</span></label>';
    }).join('') + '</div>';
  }

  // Instrucción según el diseño de cada formato; si no aplica, la del banco.
  function instructionFor(q) {
    if (q.format === 'most_least') {
      return touchFirst
        ? 'Toca una opción y luego la casilla donde va, o arrástrala desde ⠿.'
        : 'Arrastra una opción a «Más probable» y otra a «Menos probable».';
    }
    if (q.format === 'pick_yes_no') {
      var verb = touchFirst ? 'Pon' : 'Arrastra';
      return verb + ' ' + q.yesCount + ' en «Sí» y ' + q.noCount + ' en «No».';
    }
    if (q.format === 'value_coherence') return 'Para cada valor, elige cómo se vive.';
    if (q.format === 'text' && phraseOf(q)) return 'Completa los espacios.';
    return q.instruction || '';
  }

  // Termina cualquier arrastre en curso y borra copias huérfanas. Es seguro
  // llamarla varias veces.
  function endDrag() {
    document.querySelectorAll('.ghost').forEach(function (ghost) { ghost.remove(); });
    document.querySelectorAll('.dcard.dragging').forEach(function (el) { el.classList.remove('dragging'); });
    document.querySelectorAll('.zone.over').forEach(function (z) { z.classList.remove('over'); });
    document.body.classList.remove('is-dragging');
    if (drag && drag.frame) cancelAnimationFrame(drag.frame);
    drag = null;
  }

  function moveGhost() {
    if (!drag || !drag.ghost) return;
    drag.frame = 0;
    drag.ghost.style.transform =
      'translate(' + (drag.x - drag.dx) + 'px,' + (drag.y - drag.dy) + 'px) rotate(-1deg) scale(1.02)';
    var over = zoneAt(drag.x, drag.y);
    document.querySelectorAll('[data-zone]').forEach(function (z) { z.classList.toggle('over', z === over); });
    if (drag.y < 70) global.scrollBy(0, -12);
    else if (drag.y > global.innerHeight - 70) global.scrollBy(0, 12);
  }

  // Mover y soltar se escuchan en la ventana: así el arrastre termina aunque
  // el puntero salga de la tarjeta, de la página o se suelte en cualquier lado.
  function onDragMove(e) {
    if (!drag || e.pointerId !== drag.pointerId) return;
    drag.x = e.clientX;
    drag.y = e.clientY;
    if (!drag.on) {
      if (Math.abs(drag.x - drag.x0) + Math.abs(drag.y - drag.y0) < 6) return;
      if (!document.body.contains(drag.el)) return endDrag();
      var rect = drag.el.getBoundingClientRect();
      drag.on = true;
      drag.dx = Math.min(drag.x0 - rect.left, 40);
      drag.dy = drag.y0 - rect.top;
      drag.ghost = drag.el.cloneNode(true);
      drag.ghost.classList.remove('picked');
      drag.ghost.classList.add('ghost');
      drag.ghost.removeAttribute('data-id');
      drag.ghost.setAttribute('aria-hidden', 'true');
      drag.ghost.style.width = rect.width + 'px';
      document.body.appendChild(drag.ghost);
      drag.el.classList.add('dragging');
      document.body.classList.add('is-dragging');
    }
    e.preventDefault();
    if (!drag.frame) drag.frame = requestAnimationFrame(moveGhost);
  }

  function onDragEnd(e) {
    if (!drag || (e && e.pointerId !== undefined && e.pointerId !== drag.pointerId)) return;
    var moved = drag.on;
    var q = drag.q;
    var id = drag.id;
    var target = moved && e && e.type === 'pointerup' ? zoneAt(e.clientX, e.clientY) : null;
    endDrag();
    if (!moved) return;
    justDragged = true;
    setTimeout(function () { justDragged = false; }, 0);
    if (target && q === current()) place(q, id, target.dataset.zone);
  }

  function cancelDrag() {
    if (drag) endDrag();
  }

  function zoneAt(x, y) {
    var hit = document.elementFromPoint(x, y);
    return hit && hit.closest ? hit.closest('[data-zone]') : null;
  }

  function bindDnd(q) {
    document.querySelectorAll('.dcard').forEach(function (el) {
      el.onclick = function () {
        if (justDragged) {
          justDragged = false;
          return;
        }
        picked = picked === el.dataset.id ? null : el.dataset.id;
        render();
      };
      el.ondragstart = function (e) { e.preventDefault(); };
      el.onpointerdown = function (e) {
        if (e.pointerType === 'mouse' && e.button !== 0) return;
        // En pantallas táctiles se arrastra desde el asa para no bloquear el scroll.
        if (e.pointerType !== 'mouse' && !e.target.closest('.grip')) return;
        endDrag();
        if (e.pointerType === 'mouse') e.preventDefault();
        drag = {
          q: q,
          el: el,
          id: el.dataset.id,
          pointerId: e.pointerId,
          x0: e.clientX,
          y0: e.clientY,
          x: e.clientX,
          y: e.clientY,
          on: false,
          ghost: null,
          frame: 0,
        };
      };
    });
    document.querySelectorAll('[data-zone]').forEach(function (zone) {
      function drop() {
        if (picked) place(q, picked, zone.dataset.zone);
      }
      zone.onclick = function (e) {
        if (e.target.closest('[data-unplace]')) return;
        drop();
      };
      zone.onkeydown = function (e) {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          drop();
        }
      };
    });
    document.querySelectorAll('[data-unplace]').forEach(function (btn) {
      btn.onclick = function () { unplace(q, btn.dataset.unplace); };
    });
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
      bindDnd(q);
      return;
    }
    if (q.format === 'most_least') {
      bindDnd(q);
      var forecast = document.getElementById('forecast');
      if (forecast) {
        forecast.oninput = forecast.onpointerup = forecast.onkeyup = function () {
          var value = Number(forecast.value);
          answer(q.id).forecast = value;
          forecast.style.setProperty('--p', value + '%');
          document.getElementById('forecast-box').classList.remove('unset');
          document.getElementById('forecast-out').textContent = value + ' %';
        };
      }
      return;
    }
    if (q.format === 'text') {
      document.querySelectorAll('[data-blank]').forEach(function (input) {
        input.oninput = function () { fills[q.id][Number(input.dataset.blank)] = input.value; };
      });
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
    if (q.format === 'text') {
      if (fills[q.id]) {
        answer(q.id).value_text = fills[q.id].map(function (part) { return part.trim(); }).join(', ');
      } else {
        answer(q.id).value_text = document.getElementById('text').value.trim();
      }
    }
    return answer(q.id);
  }

  function valid(q, a) {
    if (q.format === 'most_least') {
      if (!a.most || !a.least || a.most === a.least) {
        return 'Pon una opción en «Más probable» y otra en «Menos probable».';
      }
      if (q.askForecast && (!Number.isInteger(a.forecast) || a.forecast < 0 || a.forecast > 100)) {
        return 'Mueve la barra para indicar el porcentaje.';
      }
      return '';
    }
    if (q.format === 'value_coherence') {
      var ratings = a.ratings || {};
      return (q.items || []).every(function (item) { return ratings[item.id]; }) ? '' : 'Califica cada valor.';
    }
    if (q.format === 'pick_yes_no') {
      return (a.yes || []).length === q.yesCount && (a.no || []).length === q.noCount
        ? '' : 'Pon ' + q.yesCount + ' en «Sí» y ' + q.noCount + ' en «No».';
    }
    if (q.format === 'text') {
      if (fills[q.id]) {
        return fills[q.id].every(function (part) { return part.trim(); }) ? '' : 'Completa los espacios.';
      }
      return a.value_text ? '' : 'Completa la frase.';
    }
    return a.value ? '' : 'Elige una opción.';
  }

  function thanks() {
    setProgress(0, 0);
    bar.style.width = '100%';
    app.innerHTML = card('Gracias por tu tiempo.', 'Ya puedes cerrar esta página.');
  }

  function render() {
    if (!survey.questions.length) {
      app.innerHTML = card('El diagnóstico aún no está publicado', 'El equipo TaleX está cargando las preguntas.');
      return;
    }
    if (index < 0) return startScreen();
    if (index >= survey.questions.length) return thanks();
    endDrag();
    var q = current();
    if (pickedFor !== index) {
      picked = null;
      pickedFor = index;
    }
    var phrase = q.format === 'text' ? phraseOf(q) : null;
    var hint = instructionFor(q);
    setProgress(index + 1, survey.questions.length);
    app.innerHTML =
      '<div class="card">' +
      '<p class="section">' + escapeHtml(q.sectionTitle || '') + '</p>' +
      (q.name && !(phrase && q.name === phrase.lead) ? '<p class="name">' + escapeHtml(q.name) + '</p>' : '') +
      '<p class="statement">' + escapeHtml(phrase ? phrase.lead || q.statement : q.statement) + '</p>' +
      (hint ? '<p class="hint">' + escapeHtml(hint) + '</p>' : '') +
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
      window.scrollTo(0, 0);
      return;
    }
    if (isDemo) {
      index = survey.questions.length;
      thanks();
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
    global.addEventListener('pointermove', onDragMove, {passive: false});
    global.addEventListener('pointerup', onDragEnd);
    global.addEventListener('pointercancel', onDragEnd);
    global.addEventListener('blur', cancelDrag);
    document.addEventListener('visibilitychange', cancelDrag);
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') {
        cancelDrag();
        if (picked) {
          picked = null;
          render();
        }
      }
    });
    document.body.innerHTML = shell('Cargando el diagnóstico…');
    app = document.getElementById('app');
    progress = document.getElementById('progress');
    bar = document.getElementById('bar');
    load();
  }

  if (document.body) mount();
  else document.addEventListener('DOMContentLoaded', mount);
})(window);
