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
      /* Arrastrar a casillas (más/menos probable y sí/no) */
      '.zones{position:sticky;top:0;z-index:2;display:grid;grid-template-columns:1fr 1fr;gap:10px;padding:10px 0;margin:-10px 0 6px;background:#f3f6fa}' +
      '.zone{min-height:86px;border:2px dashed #b9c6d6;border-radius:12px;background:#ffffff;padding:10px;transition:border-color .15s,background .15s,transform .15s;cursor:default;outline:none}' +
      '.zone-head{display:flex;justify-content:space-between;align-items:center;gap:8px;margin-bottom:8px}' +
      '.zone-title{font-size:12px;font-weight:700;letter-spacing:1px;text-transform:uppercase}' +
      '.zone-count{font-size:12px;font-weight:700;color:#596779}' +
      '.zone.pos .zone-title{color:#3b6d11}.zone.neg .zone-title{color:#254a78}' +
      '.zone.full{border-style:solid}.zone.pos.full{border-color:#a4e765}.zone.neg.full{border-color:#254a78}' +
      '.zone-empty{display:block;font-size:13px;color:#8a97a8;padding:6px 2px}' +
      '.zone.armed{cursor:pointer;border-color:#0b1528;background:#f8fbff}' +
      '.zone.over{border-color:#0b1528;border-style:solid;background:#eef5ff;transform:scale(1.015)}' +
      '.placed{display:flex;align-items:center;gap:8px;padding:8px 8px 8px 10px;margin-top:6px;border-radius:8px;font-size:14px;line-height:1.35;font-weight:700}' +
      '.zone.pos .placed{background:#eef9e2;color:#0b1528}.zone.neg .placed{background:#e8eef6;color:#0b1528}' +
      '.placed span{flex:1}' +
      '.unplace{flex:none;width:26px;height:26px;padding:0;border-radius:50%;background:#ffffff;color:#596779;font-size:16px;line-height:26px}' +
      '.pool{display:grid;gap:8px}' +
      '.dcard{display:flex;align-items:center;gap:10px;width:100%;text-align:left;padding:12px 14px;border:1px solid #dce4ee;border-radius:10px;background:#ffffff;color:#0b1528;font:400 15px/1.4 Arial,Helvetica,sans-serif;letter-spacing:0;cursor:grab;touch-action:pan-y;user-select:none;-webkit-user-select:none;transition:border-color .15s,box-shadow .15s,opacity .15s}' +
      '.dcard:hover{border-color:#254a78;box-shadow:0 2px 10px rgba(11,21,40,.08)}' +
      '.dcard.picked{border-color:#0b1528;box-shadow:0 0 0 2px #0b1528}' +
      '.dcard.dragging{opacity:.3;border-style:dashed;box-shadow:none}' +
      '.grip{flex:none;display:grid;grid-template-columns:repeat(2,4px);gap:3px;padding:4px;touch-action:none;cursor:grab}' +
      '.grip i{width:4px;height:4px;border-radius:50%;background:#9aa8b9}' +
      '.ghost{position:fixed;left:0;top:0;z-index:50;pointer-events:none;margin:0;max-width:min(520px,86vw);border-color:#0b1528;box-shadow:0 14px 34px rgba(11,21,40,.22);will-change:transform}' +
      'body.is-dragging,body.is-dragging *{cursor:grabbing!important;user-select:none;-webkit-user-select:none}' +
      'body.is-dragging .zone{border-color:#7f93ab}' +
      'body.is-dragging .zone.over{border-color:#0b1528}' +
      /* Pronóstico */
      '.forecast{margin-top:20px;padding:18px;border-radius:12px;background:#ffffff;border:1px solid #dce4ee}' +
      '.forecast-q{margin:0 0 10px;font-size:15px;line-height:1.5;color:#0b1528;font-weight:700}' +
      '.forecast-pick{display:inline-block;margin:0 0 14px;padding:6px 10px;border-radius:8px;background:#eef9e2;font-size:13px;color:#0b1528}' +
      '.forecast-row{display:flex;align-items:center;gap:16px}' +
      '.forecast-out{flex:none;min-width:84px;text-align:right;font-size:32px;font-weight:700;letter-spacing:-.5px;color:#0b1528}' +
      '.forecast.unset .forecast-out{font-size:14px;font-weight:700;color:#8a97a8;letter-spacing:0}' +
      'input[type=range]{flex:1;-webkit-appearance:none;appearance:none;height:10px;border-radius:999px;background:linear-gradient(90deg,#254a78 0,#a4e765 var(--p,50%),#dce4ee var(--p,50%));outline:none;margin:0}' +
      '.forecast.unset input[type=range]{background:#dce4ee}' +
      'input[type=range]::-webkit-slider-thumb{-webkit-appearance:none;width:28px;height:28px;border-radius:50%;background:#ffffff;border:3px solid #0b1528;box-shadow:0 2px 8px rgba(11,21,40,.25);cursor:grab}' +
      'input[type=range]::-moz-range-thumb{width:24px;height:24px;border-radius:50%;background:#ffffff;border:3px solid #0b1528;cursor:grab}' +
      '.forecast-scale{display:flex;justify-content:space-between;margin:8px 100px 0 0;font-size:12px;color:#8a97a8}' +
      /* Se vive / A medias / Solo en la pared */
      '.values{display:grid;gap:12px}' +
      '.value-card{padding:16px;border-radius:12px;background:#ffffff;border:1px solid #dce4ee;border-left:6px solid #dce4ee;transition:border-color .2s,background .2s}' +
      '.value-card.k-vive{border-left-color:#a4e765;background:#fbfef7}.value-card.k-medias{border-left-color:#f5b83d;background:#fffcf3}.value-card.k-pared{border-left-color:#596779;background:#f7f8fa}' +
      '.value-name{margin:0 0 12px;font-size:20px;font-weight:700;color:#0b1528}' +
      '.tiles{display:grid;grid-template-columns:repeat(3,1fr);gap:8px}' +
      '.tile{display:flex;flex-direction:column;align-items:center;gap:8px;padding:14px 8px;border:2px solid #dce4ee;border-radius:10px;background:#ffffff;color:#0b1528;font:700 13px/1.2 Arial,Helvetica,sans-serif;letter-spacing:0;transition:transform .12s,border-color .15s,background .15s}' +
      '.tile:hover{transform:translateY(-2px);border-color:#9aa8b9}' +
      '.tile svg{width:28px;height:28px}' +
      '.tile.k-vive{color:#3b6d11}.tile.k-medias{color:#9a5b00}.tile.k-pared{color:#596779}' +
      '.tile.on{transform:none}' +
      '.tile.k-vive.on{background:#a4e765;border-color:#a4e765;color:#0b1528}' +
      '.tile.k-medias.on{background:#f5b83d;border-color:#f5b83d;color:#0b1528}' +
      '.tile.k-pared.on{background:#596779;border-color:#596779;color:#ffffff}' +
      '.tile.on span{color:inherit}' +
      '.values-count{margin:0 0 10px;font-size:13px;color:#596779}' +
      /* Completar la frase */
      '.fill{display:flex;flex-wrap:wrap;align-items:baseline;gap:10px 8px;margin:0;padding:18px;border-radius:12px;background:#ffffff;border:1px solid #dce4ee;font-size:20px;line-height:1.6;color:#0b1528}' +
      '.blank{flex:1 1 220px;min-width:0;border:0;border-bottom:2px solid #254a78;border-radius:0;padding:4px 2px;background:transparent;font:700 20px/1.4 Arial,Helvetica,sans-serif;color:#0b1528;outline:none}' +
      '.blank:focus{border-bottom-color:#a4e765;background:#fbfef7}' +
      '.blank::placeholder{color:#b9c6d6;font-weight:400}' +
      '.actions{display:flex;justify-content:space-between;gap:12px;margin-top:22px}' +
      'button{border:0;cursor:pointer;font:700 14px/1 Arial,Helvetica,sans-serif;letter-spacing:.02em;padding:13px 20px;border-radius:8px}' +
      '.next{background:#0b1528;color:#ffffff}' +
      '.back{background:transparent;color:#254a78;padding-left:0}' +
      '.error{color:#b42318;margin-top:12px;font-size:14px}' +
      '.count{font-size:13px;color:#596779;margin:0 0 12px}' +
      '@media (max-width:640px){.opt{grid-template-columns:1fr}.chip{width:100%}.zone{min-height:74px}.tiles{gap:6px}.tile{padding:12px 4px;font-size:12px}.forecast-scale{margin-right:0}.forecast-row{flex-direction:column-reverse;align-items:stretch;gap:8px}.forecast-out{text-align:left}.fill{font-size:18px}.blank{font-size:18px}}' +
      '</style>',
  );

  var app;
  var progress;
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
      '<p class="eyebrow">Diagnóstico cultural</p>' +
      '<h1>' + escapeHtml(title) + '</h1>' +
      '<p class="lead">' + escapeHtml(body) + '</p>' +
      (action || '')
    );
  }

  function startScreen() {
    progress.textContent = '';
    app.innerHTML = card(
      survey.title || 'Diagnóstico cultural',
      survey.intro || 'Responde con calma. No hay respuestas correctas.',
      '<button class="next" type="button" id="start">Empezar</button>',
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
    var value = set ? a.forecast : 50;
    var prompt = String(q.forecastPrompt || '').replace(/\s*\(\s*0\s*a\s*100\s*%?\s*\)\s*$/i, '');
    return '<div class="forecast' + (set ? '' : ' unset') + '" id="forecast-box">' +
      '<p class="forecast-q">' + escapeHtml(prompt) + '</p>' +
      (a.most ? '<span class="forecast-pick">Tu más probable: «' + escapeHtml(optionLabel(q, a.most)) + '»</span>' : '') +
      '<div class="forecast-row">' +
        '<input id="forecast" type="range" min="0" max="100" step="5" value="' + value + '" style="--p:' + value + '%" aria-label="Porcentaje">' +
        '<output class="forecast-out" id="forecast-out">' + (set ? value + ' %' : 'Desliza') + '</output>' +
      '</div>' +
      '<div class="forecast-scale"><span>Nadie</span><span>La mitad</span><span>Todos</span></div>' +
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
        forecast.oninput = function () {
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
    progress.textContent = '';
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
    progress.textContent = index + 1 + ' / ' + survey.questions.length;
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
    load();
  }

  if (document.body) mount();
  else document.addEventListener('DOMContentLoaded', mount);
})(window);
