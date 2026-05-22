# 📌 Lembrei

Aplicativo mobile desenvolvido em **Flutter** para registrar e organizar lembretes do dia a dia, ajudando a não esquecer compromissos, tarefas e ideias importantes.

## ✨ Funcionalidades

- ✅ Criar, editar e excluir lembretes
- 📅 Organizar por data e categoria
- 🔔 Notificações de lembretes próximos
- ☁️ Sincronização na nuvem com Supabase
- 🌙 Interface simples e intuitiva

## 🛠️ Tecnologias utilizadas

- [Flutter](https://flutter.dev/) - Framework multiplataforma
- [Dart](https://dart.dev/) - Linguagem de programação
- [Supabase](https://supabase.com/) - Backend (banco de dados e autenticação)

## 📱 Plataformas suportadas

- Android
- iOS
- Web
- Windows
- macOS
- Linux

## 🚀 Como rodar o projeto

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado
- Editor de código (VS Code ou Android Studio)
- Conta no [Supabase](https://supabase.com/)

### Passo a passo

Clone o repositório:

```bash
git clone https://github.com/isamedeirospassos/lembrei_app.git
```

Entre na pasta:

```bash
cd lembrei_app
```

Instale as dependências:

```bash
flutter pub get
```

Crie um arquivo `.env` na raiz do projeto com suas chaves do Supabase:

```env
SUPABASE_URL=sua_url_aqui
SUPABASE_ANON_KEY=sua_chave_aqui
```

Execute o app:

```bash
flutter run
```

## 📂 Estrutura do projeto

```
lembrei_app/
├── lib/              # Código principal em Dart
├── assets/           # Imagens e recursos
├── android/          # Configurações Android
├── ios/              # Configurações iOS
├── web/              # Configurações Web
├── supabase/         # Configurações do Supabase
├── pubspec.yaml      # Dependências do projeto
└── README.md
```

## 📌 Status do projeto

🚧 Em desenvolvimento

## 👩‍💻 Autora

Feito com 💜 por [Isabella Medeiros Passos](https://github.com/isamedeirospassos)