# 📌 Lembrei

Aplicativo mobile inteligente desenvolvido em **Flutter** para criar lembretes contextuais usando linguagem natural, geolocalização e IA.

Em vez de só agendar por horário, o Lembrei entende frases como *"me lembra de levar o carregador quando eu sair de casa"* e aciona o lembrete no momento certo. 🧠✨

## ✨ Funcionalidades

- 🗣️ Criação de lembretes em **linguagem natural**
- 📅 Lembretes por **data e hora**
- 📍 Lembretes por **localização** (chegou/saiu de um lugar)
- 🧠 Classificação automática com **IA** (prioridade, tags, contexto)
- 🔁 Lembretes **recorrentes** (diário, semanal)
- 😴 Função **soneca** (snooze)
- 🔐 Autenticação segura de usuários
- ☁️ Sincronização em nuvem em tempo real

## 🛠️ Tecnologias utilizadas

### Frontend
- [Flutter](https://flutter.dev/) - Framework de desenvolvimento mobile
- [Dart](https://dart.dev/) - Linguagem de programação

### Backend & Banco de Dados
- [Supabase](https://supabase.com/) - Backend as a Service
- **PostgreSQL** - Banco de dados relacional
- **PostGIS** - Extensão para dados geoespaciais
- **SQL** - Migrations, triggers, índices e políticas RLS

### Segurança
- **Row Level Security (RLS)** - Cada usuário acessa apenas seus próprios dados
- **Supabase Auth** - Autenticação de usuários

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

Execute as migrations SQL no painel do Supabase (arquivo `supabase/migrations/001_initial.sql`).

Rode o app no Android:

```bash
flutter run
```

## 📌 Status do projeto

🚧 Concluído

## 👩‍💻 Autora

Feito com 💜 por [Isabella Medeiros Passos](https://github.com/isamedeirospassos)