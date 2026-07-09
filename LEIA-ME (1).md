# SCF RH — Deploy no Netlify + Supabase (grátis)

Este pacote tem 3 arquivos:
- `index.html` → o sistema (front-end)
- `supabase-setup.sql` → script para criar a tabela e a segurança no banco
- `LEIA-ME.md` → este guia

---

## Parte 1 — Criar o projeto no Supabase

1. Acesse **https://supabase.com** e entre na sua conta.
2. Clique em **New project**.
   - Escolha uma organização (ou crie uma).
   - Dê um nome, ex: `scf-rh`.
   - Crie uma senha de banco (guarde num lugar seguro — não é a senha de login do app, é do banco).
   - Escolha a região mais próxima (ex: South America / São Paulo se disponível).
   - Clique em **Create new project** e aguarde ~2 minutos.

3. **Rodar o script SQL:**
   - No menu lateral, clique em **SQL Editor**.
   - Clique em **New query**.
   - Abra o arquivo `supabase-setup.sql` (deste pacote), copie tudo e cole no editor.
   - Clique em **Run**. Deve aparecer "Success. No rows returned".

4. **Pegar a URL e a chave pública:**
   - No menu lateral, clique em **Project Settings** (ícone de engrenagem) → **API**.
   - Copie o **Project URL** (algo como `https://xxxxxxxx.supabase.co`).
   - Copie a chave **anon public** (uma chave longa começando com `eyJ...`).

5. **(Recomendado) Ajustar confirmação de e-mail:**
   - Vá em **Authentication** → **Providers** → **Email**.
   - Se quiser que o primeiro acesso já entre direto (sem precisar clicar em link de e-mail), desative **Confirm email**.
   - Se deixar ativado, funciona também — só que depois de criar a conta a pessoa precisa abrir o e-mail e confirmar antes do primeiro login.

---

## Parte 2 — Colocar a URL e a chave no sistema

1. Abra o arquivo `index.html` em um editor de texto (Bloco de Notas, VS Code, etc).
2. Procure por estas duas linhas (perto do topo do `<script>`):
   ```js
   const SUPABASE_URL = 'COLE_AQUI_A_SUA_PROJECT_URL';
   const SUPABASE_ANON_KEY = 'COLE_AQUI_A_SUA_ANON_PUBLIC_KEY';
   ```
3. Troque pelos valores copiados no passo 4 da Parte 1. Exemplo:
   ```js
   const SUPABASE_URL = 'https://xxxxxxxx.supabase.co';
   const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
   ```
4. Salve o arquivo.

> A chave "anon public" é feita para ser usada no navegador — não tem problema ela aparecer no código. A segurança real está nas regras (RLS) criadas pelo script SQL, que só liberam dados para quem estiver logado.

---

## Parte 3 — Publicar no Netlify

**Opção mais simples (arrastar e soltar):**

1. Acesse **https://app.netlify.com** e entre na sua conta (ou crie uma grátis).
2. Vá em **Sites** → você verá uma área escrito algo como "Drag and drop your site output folder here".
3. Arraste a pasta que contém o `index.html` (só essa pasta, com o arquivo já editado com sua URL/chave) para essa área.
4. Aguarde o deploy (~10 segundos). O Netlify já te dá um link tipo `https://algum-nome-aleatorio.netlify.app`.
5. (Opcional) Em **Site settings → Change site name**, troque para um nome melhor, tipo `scf-rh-suaempresa.netlify.app`.

Pronto — o sistema já está no ar, funcionando com login real e dados salvos no Supabase.

---

## Parte 4 — Criar o primeiro acesso (você vira Master automaticamente)

1. Abra o link do Netlify.
2. Clique em **"Primeiro acesso? Criar acesso"**.
3. Preencha nome, e-mail e senha (mínimo 6 caracteres) e envie.
4. Se a confirmação de e-mail estiver ativada no Supabase, confira sua caixa de entrada, clique no link de confirmação e depois faça login normalmente.

**A primeiríssima pessoa a criar acesso no sistema vira automaticamente Master** — não precisa configurar nada a mais para isso. A partir daí, use a tela **Usuários** (só aparece no menu para quem é Master) para cadastrar o restante da equipe, já escolhendo o papel de cada um:

- **Master** — acesso total, incluindo cadastrar/gerenciar outros usuários.
- **Editor** — pode cadastrar e editar colaboradores, unidades e folgas, mas não pode excluir nada.
- **Visualizador** — só consulta o Dashboard, Cadastro, Controle e Relatórios; não vê nenhum botão de cadastrar/editar/excluir.

Importante: quem você cadastra pela tela Usuários **não passa pela tela "Criar acesso"** — a pessoa já recebe login pronto (e-mail + senha que você definiu) e entra direto pela tela de login normal.

Para desativar o acesso de alguém (a pessoa não consegue mais entrar, mas o histórico dela continua no sistema), use o botão "Desativar" na tela Usuários. Não é possível excluir a conta de login por completo pelo app — isso exigiria expor uma chave sensível do Supabase no navegador, o que seria um risco de segurança.

A partir daí, cadastre unidades, colaboradores e comece a lançar as folgas.

---

## Perguntas comuns

**Posso ter mais de uma pessoa usando login?**
Sim. Só a primeira pessoa cria o próprio acesso pela tela "Criar acesso" (e vira Master automaticamente). Todos os demais são cadastrados pelo Master na tela **Usuários**, com o papel Master, Editor ou Visualizador. Colaboradores, unidades e folgas são compartilhados entre todos os usuários logados.

**Qual a diferença entre Master, Editor e Visualizador?**
- Master: acesso total, incluindo gerenciar outros usuários.
- Editor: cadastra e edita colaboradores/unidades/folgas, mas não exclui nada.
- Visualizador: só consulta (Dashboard, Cadastro, Controle, Relatórios), sem nenhum botão de ação.

**É realmente grátis?**
Sim, para esse volume de uso o plano gratuito do Netlify e do Supabase é suficiente. O Supabase free tier pausa o projeto após alguns dias sem uso — é só abrir o painel do Supabase e reativar (leva ~1 minuto) se isso acontecer.

**Esqueci a senha, como redefinir?**
Hoje o app não tem tela de "esqueci a senha". Se isso acontecer, é possível redefinir manualmente pelo painel do Supabase em **Authentication → Users**, clicando nos "..." do usuário e escolhendo "Send password recovery" ou definindo uma nova senha diretamente. Posso adicionar uma tela de "esqueci a senha" no app se você quiser.

**Quero atualizar o sistema depois de publicado.**
Basta editar o `index.html` de novo e arrastar a pasta atualizada para a mesma área do Netlify (ou, se preferir, conectar o site a um repositório do GitHub para atualizar via `git push`). **Atenção:** confirme que as linhas `SUPABASE_URL` e `SUPABASE_ANON_KEY` continuam preenchidas com os valores do seu projeto antes de subir — se eu te enviar uma versão nova do arquivo, ela volta com os campos em branco e você precisa colar os valores de novo.

