-- ============================================================
-- SCF RH — Setup do banco de dados no Supabase
-- Cole este script inteiro no SQL Editor do seu projeto Supabase
-- (menu lateral "SQL Editor" > "New query") e clique em "Run".
-- ============================================================

-- Tabela única que guarda os "blocos" de dados do sistema
-- (perfil, colaboradores, unidades, folgas), cada um em uma linha.
create table if not exists app_data (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

-- Ativa Row Level Security: sem isso, RLS fica desligado e
-- qualquer pessoa com a chave pública poderia ler/escrever.
alter table app_data enable row level security;

-- Remove policies antigas (caso você rode o script de novo)
drop policy if exists "Usuarios autenticados podem ler" on app_data;
drop policy if exists "Usuarios autenticados podem gravar" on app_data;
drop policy if exists "Usuarios autenticados podem atualizar" on app_data;
drop policy if exists "Usuarios autenticados podem apagar" on app_data;

-- Só usuários LOGADOS (via Supabase Auth) podem ler os dados
create policy "Usuarios autenticados podem ler"
  on app_data for select
  to authenticated
  using (true);

-- Só usuários LOGADOS podem inserir
create policy "Usuarios autenticados podem gravar"
  on app_data for insert
  to authenticated
  with check (true);

-- Só usuários LOGADOS podem atualizar
create policy "Usuarios autenticados podem atualizar"
  on app_data for update
  to authenticated
  using (true)
  with check (true);

-- Só usuários LOGADOS podem apagar (o app não apaga linhas hoje, mas fica pronto)
create policy "Usuarios autenticados podem apagar"
  on app_data for delete
  to authenticated
  using (true);

-- Mantém updated_at sempre atualizado automaticamente
create or replace function set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_app_data_updated_at on app_data;
create trigger trg_app_data_updated_at
  before update on app_data
  for each row execute function set_updated_at();

-- ============================================================
-- Usuários e permissões (Master / Editor / Visualizador)
-- ============================================================

create table if not exists usuarios_perfil (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null,
  email text not null,
  foto text,
  papel text not null default 'visualizador' check (papel in ('master','editor','visualizador')),
  ativo boolean not null default true,
  criado_em timestamptz not null default now()
);

alter table usuarios_perfil enable row level security;

drop policy if exists "leitura autenticada" on usuarios_perfil;
drop policy if exists "insercao" on usuarios_perfil;
drop policy if exists "atualizacao" on usuarios_perfil;

-- Qualquer pessoa logada pode ler a lista (necessário para a tela "Usuários" e para o próprio login)
create policy "leitura autenticada"
  on usuarios_perfil for select
  to authenticated
  using (true);

-- Inserção: o 1º usuário do sistema pode se auto-cadastrar (vira master);
-- depois disso, só um master pode cadastrar novos usuários
create policy "insercao"
  on usuarios_perfil for insert
  to authenticated
  with check (
    (id = auth.uid() and not exists (select 1 from usuarios_perfil))
    or exists (select 1 from usuarios_perfil up where up.id = auth.uid() and up.papel = 'master' and up.ativo)
  );

-- Atualização: o próprio usuário pode editar seus dados (nome/foto/email),
-- e um master pode editar qualquer usuário (papel, status, etc.)
create policy "atualizacao"
  on usuarios_perfil for update
  to authenticated
  using (
    id = auth.uid()
    or exists (select 1 from usuarios_perfil up where up.id = auth.uid() and up.papel = 'master' and up.ativo)
  )
  with check (
    id = auth.uid()
    or exists (select 1 from usuarios_perfil up where up.id = auth.uid() and up.papel = 'master' and up.ativo)
  );

-- Trava extra: impede que um usuário comum mude o próprio papel ou reative/desative a si mesmo
create or replace function protege_papel_ativo()
returns trigger as $$
declare
  eh_master boolean;
begin
  select exists(
    select 1 from usuarios_perfil up where up.id = auth.uid() and up.papel = 'master' and up.ativo
  ) into eh_master;
  if not eh_master then
    if new.papel is distinct from old.papel or new.ativo is distinct from old.ativo then
      raise exception 'Apenas um Master pode alterar papel ou status de acesso.';
    end if;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_protege_papel_ativo on usuarios_perfil;
create trigger trg_protege_papel_ativo
  before update on usuarios_perfil
  for each row execute function protege_papel_ativo();
