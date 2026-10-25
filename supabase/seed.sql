-- Catalog and survey workspaces. Does not invent culture questions.

insert into public.survey_templates (slug, purpose, title, description)
values
  (
    'affinity-core',
    'affinity',
    'Encuesta de afinidad TaleX',
    'Valores, necesidades y experiencias. Gemini lee este banco en Postgres.'
  ),
  (
    'culture-perception',
    'culture_perception',
    'Percepción cultural TaleX',
    'Encuesta que responden empresas o sus empleados para conocer la cultura vivida. Lista para cargar preguntas.'
  )
on conflict (slug) do nothing;

insert into public.survey_versions (template_id, version_number, status, published_at)
select id, 1, 'published', now()
from public.survey_templates
where slug = 'affinity-core'
on conflict (template_id, version_number) do nothing;

insert into public.survey_versions (template_id, version_number, status)
select id, 1, 'draft'
from public.survey_templates
where slug = 'culture-perception'
on conflict (template_id, version_number) do nothing;

insert into public.survey_sections (version_id, code, title, sort_order)
select v.id, seed.code, seed.title, seed.sort_order
from public.survey_versions v
join public.survey_templates t on t.id = v.template_id
join (
  values
    ('culture-perception', 'cultura', 'Cultura vivida', 1),
    ('culture-perception', 'liderazgo', 'Liderazgo y decisiones', 2),
    ('culture-perception', 'trabajo', 'Forma de trabajar', 3),
    ('culture-perception', 'personas', 'Personas y relaciones', 4),
    ('culture-perception', 'apertura', 'Comentarios abiertos', 5)
) as seed(slug, code, title, sort_order) on seed.slug = t.slug
where v.status = 'draft'
on conflict (version_id, code) do nothing;
