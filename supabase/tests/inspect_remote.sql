select tablename
from pg_tables
where schemaname = 'public'
order by 1;
