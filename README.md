# 📌 Lembrei

Aplicativo mobile desenvolvido em Flutter para criar e gerenciar lembretes de forma simples, bonita e personalizável — com sincronização em nuvem, notificações locais e widget na tela inicial. ✨

## 🎯 Sobre o projeto

O Lembrei nasceu com a proposta de ser um app de lembretes leve, com identidade visual marcante (tipografia Special Elite + tema rosa) e uma experiência que vai além do básico: tem temas customizáveis, modo escuro, widget nativo no Android, sincronização em nuvem e organização por categorias.

Uma versão funcional, polida e pronta para uso no dia a dia. 💜

## ✨ Funcionalidades

- 📝 Criação, edição e exclusão de lembretes
- ⏰ Lembretes por horário + dias da semana ou data específica
- 🏷️ Categorias customizáveis (nome, cor e ícone)
- ✅ Marcar como concluído sem perder da lista
- 🗑️ Histórico de concluídos e excluídos (com restauração)
- 🔔 Notificações locais agendadas
- 📲 Widget na tela inicial com os lembretes do dia
- ⚠️ Indicador visual de lembretes atrasados
- 🔍 Busca e filtros por categoria e status
- 📊 Tela de estatísticas de produtividade
- 🎨 Vários temas visuais + modo claro/escuro
- ☁️ Sincronização em nuvem com Supabase
- 💾 Cache offline com SharedPreferences
- ☁️ Sincronização em nuvem em tempo real

## 🛠️ Tecnologias utilizadas

### Frontend

- Flutter — framework mobile
- Dart — linguagem de programação
- Provider — gerenciamento de estado
- Google Fonts — tipografia personalizada
- home_widget — widget na home do Android
- flutter_local_notifications — notificações locais
- shared_preferences — armazenamento local

### Backend & Banco de Dados

- Supabase — Backend as a Service
- PostgreSQL — banco de dados relacional
- Supabase Auth — autenticação anônima por dispositivo
- Row Level Security (RLS) — cada usuário acessa apenas seus próprios dados

## 📱 Plataforma

📱 **Android** - foco principal do desenvolvimento

## 🗄️ Estrutura do banco de dados

O projeto utiliza duas tabelas principais:

- **`profiles`** → dados do usuário
- **`reminders`** → lembretes com suporte a:
  - Texto bruto e processado por IA
  - Gatilhos por data, localização ou contexto
  - Coordenadas geográficas (lat/lng + raio)
  - Tags e prioridade definidas por IA
  - Status (concluído, adiado, notificado)

## 🚀 Como rodar o projeto

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Dispositivo ou emulador **Android**
- Conta no [Supabase](https://supabase.com/)
- Editor (VS Code ou Android Studio)

### Passo a passo

Clone o repositório:

```bash
git clone https://github.com/isamedeirospassos/lembrei_app.git
cd lembrei_app
```

Instale as dependências:

```bash
flutter pub get
```

Crie um arquivo `.env` na raiz com suas chaves do Supabase:

```env
SUPABASE_URL=sua_url_aqui
SUPABASE_ANON_KEY=sua_chave_aqui
```

Configure o Supabase

```bash
- Configure o Supabase
- Crie a tabela lembretes (estrutura acima)
- Habilite Anonymous Sign-ins em Authentication → Providers
- Configure as políticas RLS com user_id = auth.uid()
```

Rode o app no Android:

```bash
flutter run
```


## 📌 Status do projeto

🚧 Concluído

## 👩‍💻 Autora

Feito com 💜 por [Isabella Medeiros Passos](https://github.com/isamedeirospassos)

## 📄 Licença

Este projeto é de uso pessoal e está disponível para fins de estudo.