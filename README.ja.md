# PmRails

PmRailsは、Ruby on Railsのアプリケーションのテストまたは開発をするためのツールセットです。
RailsやRailsが依存するものをローカル環境にインストールすることなく使用できます。
[Podman](https://docs.podman.io/en/latest/)を活用し、Railsプロジェクトのための隔離されたコンテナ環境を作成します。


## PmRailsを利用するメリット

- **ローカル環境の汚染防止**: RailsやRailsが依存するものをローカルにインストールする必要がありません。
- **迅速なセットアップ**: Podmanがインストールされていれば、すぐに開発を開始できます。
- **一貫性と再現性のある環境**: 隔離されたコンテナが依存関係の競合を防ぐため、チーム開発にも最適です。
- **安全かつ自在な実験**: 異なるバージョンや設定を安全にテストできます。


## 機能

PmRailsは以下のコマンドを提供します。

- **`pmrails-new`**: `rails new`のラッパーとして、新しいRailsアプリケーションを作成します。\
  **使用方法**: `pmrails-new RAILS_VERSION APP_PATH [OPTIONS]`

- **`pmrails-new-plus`**: PmRailsを用いた新しいRailsアプリケーションの開発のための典型的なセットアップを一度に行います。\
  **使用方法**: `pmrails-new-plus RAILS_VERSION APP_PATH [OPTIONS]`

- **`pmrails-init`**: 既存のRailsアプリケーションに対して、PmRailsの標準的な設定ファイル一式を生成します。\
  **使用方法**: `pmrails-init [OPTIONS]`

- **`pmrails-run`**: プロジェクトローカルなランタイムディレクトリを持つ単一のRailsコンテナ内で任意のコマンドを実行します。\
  **使用方法**: `pmrails-run COMMAND [ARG...]`

- **`pmrails-compose`**: `podman-compose`のラッパーとして、プロジェクトのCompose環境を操作します。\
  **使用方法**: `pmrails-compose [GLOBAL_OPTIONS] COMMAND [COMMAND_OPTIONS]`

- **`pmrails-cmpexe`**: プロジェクトのCompose環境のRailsコンテナ内で任意のコマンドを実行します。\
  **使用方法**: `pmrails-cmpexe COMMAND [ARG...]`

- **`pmrails-apply-dockerfile`**: 設定されたDockerfileからカスタムRailsイメージを再ビルドし、Composeの`rails-app`コンテナが既に存在する場合は、新しいイメージから再生成します。\
  **使用方法**: `pmrails-apply-dockerfile`

### 非推奨コマンド

以下のレガシーコマンドは後方互換性のために残されており、将来のリリースで削除される予定です。

- `pmrails` → 代わりに `pmrails-run bin/rails` を使用してください。
- `pmbundle` → 代わりに `pmrails-run bundle` を使用してください。
- `pmrailsenvexec` → 代わりに `pmrails-run` を使用してください。


## インストール

### 事前準備

Podmanが必要です。[Podmanインストール手順](https://podman.io/docs/installation)の中からお使いのOS用の手順に従ってください。

**後述のモード3で`pmrails-compose`を利用する場合は、`podman-compose`も必要です。**

> **重要:** PyPIから比較的新しいバージョンの`podman-compose`をインストールする必要があります。デフォルトのOSパッケージマネージャー（`apt`など）が提供するバージョンは古すぎることが多く、PmRailsで正しく動作しない場合があります。インストールには[`pipx`](https://pipx.pypa.io/stable/how-to/install-pipx/)を使用することを強くお勧めします。

Ubuntu/Debianで`pipx`を使用するインストール例:

```sh
# pipxをインストール
sudo apt update
sudo apt install pipx
pipx ensurepath

# PATHの変更を適用するためにシェルを再ロード
exec $SHELL -l

# PyPIから最新のpodman-composeをインストール
pipx install podman-compose
```

その他のOSでは、[公式のpipxインストールガイド](https://pipx.pypa.io/stable/how-to/install-pipx/)に従って`pipx`をインストールし、`pipx install podman-compose`を実行してください。詳細は、[podman-composeリポジトリ](https://github.com/containers/podman-compose)を参照してください。

### PmRailsのインストール

以下の例のように、任意の場所にPmRailsをダウンロードします。

```sh
mkdir -p ~/.var
cd ~/.var
git clone https://github.com/wakairo/pmrails.git
```

PmRailsの`bin`ディレクトリをシステムのPATH環境変数に追加します。
以下は、bashを使用している場合の例です。

```sh
echo 'export PATH="$HOME/.var/pmrails/bin:$PATH"' >> ~/.bashrc
exec $SHELL -l
```

### (オプション) エイリアスの設定

PmRailsには、よく使われるコマンドを短く書くためのエイリアスを定義した`aliases`ファイルが同梱されています。

これを読み込むと、以下のようなコマンドを

```sh
pmrails-cmpexe bin/rails console
```

次のように短く書けます。

```sh
pmrails-crails console
```

エイリアスをインストールするには、シェルのスタートアップスクリプトにファイル内容を追記し、シェルを再ロードします。bashの場合は以下のようになります。

```sh
cat ~/.var/pmrails/aliases >> ~/.bashrc
exec $SHELL -l
```

これにより、以下のエイリアスが追加されます。

```sh
# pmrails aliases
alias pmrails-rrails='pmrails-run bin/rails'
alias pmrails-crails='pmrails-cmpexe bin/rails'
```


## 使用方法

PmRailsには主に3つの使い方（モード）があります。

1. **新しいRailsアプリケーションの作成のみ** — コンテナ内で`rails new`を実行します。
2. **単一のRailsコンテナでの作成と開発** — 管理されたgemストアを使用し、日常開発でのRails関連コマンドの実行では`pmrails-run`を使用します。
3. **Composeを使った作成と開発** — 同じく管理されたgemストアを使用し、`.pmrails/compose.yaml`と`pmrails-compose`を使用してマルチコンテナ環境（Rails + データベース + Seleniumなど）を操作します。

これらのモードは同じ構成要素を共有しており、自由に組み合わせることができます。

- カスタムRailsコンテナイメージ（`.pmrails/Dockerfile`）は、マルチコンテナ構成の有無に関わらず使用できます。
- マルチコンテナ構成（`.pmrails/compose.yaml`）は、カスタムRailsコンテナイメージの有無に関わらず使用できます。
- `pmrails-init`は`Dockerfile`と`compose.yaml`の両方を生成しますが、必要なものだけを残して利用できます。

### 新規作成時のRailsバージョン指定

`pmrails-new`と`pmrails-new-plus`は、RubyGemsからRailsをインストールしてから`rails new`を実行します。
`8.1`のような記号を含まない数値だけの指定は`'~> 8.1.0'`へ自動展開され、互換性のあるRails 8.1.xの最新リリースがインストールされてアプリケーションが生成されます。
自動展開を避ける場合は、厳密なバージョン固定なら`'= 8.1.0'`のように、明示的なRubyGems requirementを渡してください。

### 1. 新しいRailsアプリケーションの作成のみ

アプリケーションの初期生成のみPmRailsで行い、開発等は別環境で行う場合には、こちらの使い方をご利用ください。
`pmrails-new`は`rails new`の薄いラッパーであり、`rails new`とほとんど同じように振る舞います。

一時ディレクトリに移動します。例えば、以下のように作成して移動します。

```sh
mkdir -p ~/tmp
cd ~/tmp
```

以下の例のように、使用したいRailsバージョンと`rails new`のオプションを指定して新しいRailsアプリケーションを作成します。

```sh
pmrails-new 8.1 new_app --database=postgresql
```

> **注意:** `8.1`のような数値のみの指定は`'~> 8.1.0'`に自動展開されます。バージョンを厳密に指定する場合は`'= 8.1.0'`を使用してください（[詳細](#新規作成時のrailsバージョン指定)）。

### 2. 単一のRailsコンテナでの作成と開発

Railsを動かす単一のコンテナを使ってPmRailsで開発を続ける場合には、こちらの使い方をご利用ください。

gemはPmRailsが管理するコンテナ環境内にインストールされるため、
ホスト側のRuby環境に影響を与えずに開発を行えます。

> **注意:** このセクションでは**SQLite**を使った開発を例として示しますが、Railsアプリケーションの設定を行うことで、外部データベース（PostgreSQLやMySQLなど）を利用することも可能です。設定例については、後述の**外部データベースの利用**を参照してください。

#### `pmrails-new-plus`を利用した新しいRailsアプリケーションの作成

一時ディレクトリに移動します。例えば、以下のように作成して移動します。

```sh
mkdir -p ~/tmp
cd ~/tmp
```

`pmrails-new-plus`を使って新しいRailsアプリケーションを作成します。

```sh
pmrails-new-plus 8.1 sample_app
```

> **注意:** `8.1`のような数値のみの指定は`'~> 8.1.0'`に自動展開されます。バージョンを厳密に指定する場合は`'= 8.1.0'`を使用してください（[詳細](#新規作成時のrailsバージョン指定)）。

なお、`pmrails-new-plus`ではアプリケーション名の後に`rails new`のオプションを指定できます。

また、`pmrails-new-plus`は以下の処理を自動で実行します。

- 新しいRailsアプリケーションを作成する
- PmRailsが管理するgemストアにgemをインストールする
- `.gitignore`に`/.pmrails/var/`と`/.pmrails/config.local`を追加する

#### Railsコマンドの実行

作成したアプリケーションのディレクトリに移動します。

```sh
cd sample_app
```

Railsのコマンドを実行するには`pmrails-run`を使用します。
例えばサーバーを起動するには、以下のコマンドを実行します。

```sh
pmrails-run bin/rails server -b 0.0.0.0
```

サーバーが立ち上がったら、ウェブブラウザで`http://localhost:3000/`にアクセスします。

#### その他のコマンドの実行例

```sh
# bundleによるgemのインストールの実行
pmrails-run bundle install

# データベースのマイグレーションの実行
pmrails-run bin/rails db:migrate
# または、エイリアスを使用した場合
pmrails-rrails db:migrate

# Railsコンソールの開始
pmrails-run bin/rails console
# または、エイリアスを使用した場合
pmrails-rrails console
```

> **ヒント:** `.pmrails/Dockerfile`を追加することで、このモードで使用されるRailsコンテナイメージをカスタマイズできます。カスタムイメージの利用にComposeは必須ではありません。詳細は[Railsコンテナイメージのカスタマイズ](#railsコンテナイメージのカスタマイズ)を参照してください。

### 3. Composeを使った作成と開発

PmRailsを用いて、Railsとデータベース、Seleniumブラウザ、またはその他のサービスを別々のコンテナとしてまとめて立ち上げたい場合には、こちらの使い方をご利用ください。
gemは、`pmrails-run`と同じように、PmRailsが管理するgemストアを使用するため、ホスト側のRuby環境は影響を受けません。

このモードでは、Compose環境を「使い捨てのコンテナ」ではなく、「長く使い続けるワークスペース」と考えてください。
通常は一度立ち上げ（up）、稼働中に多くの`exec`コマンドを実行し、作業を中断したいときには停止（stop）し、再開するときには起動（start）し、最終的に不要になったら破棄（down）します。

このモデルには重要なルールが1つあります。Composeを使って作業している間は、Rails関連コマンドを`pmrails-run`ではなく、`pmrails-cmpexe ...`を通じて実行してください。
`pmrails-run`は隔離されたコンテナで実行するため、Composeによって管理されているデータベースやSelenium、その他のサービスと通信することができません。

#### プロジェクトの準備

まず、新しいRailsアプリケーションを作成します。例えば以下のように作成します。

```sh
mkdir -p ~/tmp
cd ~/tmp
pmrails-new-plus 8.1 sample_app --database=postgresql
```

> **注意:** `8.1`のような数値のみの指定は`'~> 8.1.0'`に自動展開されます。バージョンを厳密に指定する場合は`'= 8.1.0'`を使用してください（[詳細](#新規作成時のrailsバージョン指定)）。

次に、作成したアプリケーションのディレクトリへ移動し、PmRails設定ファイル一式を生成します。

```sh
cd sample_app
pmrails-init --database=postgresql
```

`--database`を指定すると、`pmrails-init`は対応するデータベース用のサービスを含む`compose.yaml`を生成します。
サポートされているのは `sqlite3`（デフォルト）、`postgresql`、`mysql`、`trilogy`、`mariadb-mysql`、および `mariadb-trilogy` です。

`pmrails-init`は、`.pmrails/config`、`.pmrails/Dockerfile`、および`.pmrails/compose.yaml`を生成します。
これらのファイルは独立して使用することも、組み合わせて使用することもできます。詳細は[設定のセクション](#設定)を参照してください。
また、`test/application_system_test_case.rb`が存在する場合はそれにパッチを当て、Composeが提供するSeleniumコンテナをシステムテストが利用できるようにします。

> **ヒント:** `pmrails-init`は複数回実行しても問題ありません。設定ファイルが既に存在する場合、既存の編集済みの内容が保持され、新しく生成された内容は`.pmrails-init`という接尾辞のついた別ファイルに書き出されます。

> **ヒント:** このモード3でも`.pmrails/Dockerfile`は必須ではありません。`.pmrails/compose.yaml`のみが存在する場合、PmRailsはプロジェクト固有のRailsコンテナイメージをビルドする代わりに公式の`ruby`イメージを使用します。

#### 日常開発でのCompose環境の操作

通常の作業の流れは以下のとおりです。

1. `pmrails-compose up -d --wait`で環境を立ち上げます。
2. 環境稼働中に`pmrails-cmpexe ...`で作業を行います。
3. 中断したいときは`pmrails-compose stop`で環境を一時停止します。
4. `pmrails-compose start --wait`で環境を再開します。
5. 作業が完了したら`pmrails-compose down`で環境を破棄します。

まずは以下のコマンドを実行します。

```sh
pmrails-compose up -d --wait
```

プロジェクトを初めて使用するとき、`.pmrails/compose.yaml`を変更した後、または環境がどのような状態かわからないときでも、`up`は使用できます。
サービスがまだ存在しない場合、`up`はそれらを作成します。既に存在しているが停止している場合、`up`はそれらを再開します。

環境が稼働したら、`exec`で作業を行います。

```sh
pmrails-cmpexe bundle install
pmrails-cmpexe bin/rails db:migrate
pmrails-cmpexe bin/rails console
pmrails-cmpexe bin/rails server
```

エイリアスを設定している場合、後ろ3つのコマンドを以下のように実行できます。

```sh
pmrails-crails db:migrate
pmrails-crails console
pmrails-crails server
```

コマンド単位で環境変数を確実にコンテナへ渡すには、`env`を介して実行します。例えば、test環境のデータベースマイグレーションは以下のコマンドで行えます。

```sh
pmrails-cmpexe env RAILS_ENV=test bin/rails db:migrate
```

> **注意:** PmRailsが生成するCompose設定にデータベースサービスが含まれる場合、`DATABASE_URL`環境変数が設定されます。`DATABASE_URL`が設定されている環境では、Railsは`db:create`においてdevelopmentデータベースと同時にtestデータベースを作成しないため、必要な場合は以下のように明示的に作成してください。
>
> ```sh
> pmrails-cmpexe env RAILS_ENV=test bin/rails db:create
> ```

Railsサーバーを起動した場合は、ブラウザで`http://localhost:3000/`を開いてください。

環境を破棄せずに作業を中断したい場合は、以下を実行します。

```sh
pmrails-compose stop
```

作業を再開する際は、停止した環境を以下で再開します。

```sh
pmrails-compose start --wait
```

`start`は、以前停止した環境をそのまま使いたいときに使用します。
`.pmrails/compose.yaml`を変更している場合は、現在の設定と環境を整合させるために、代わりに`pmrails-compose up -d --wait`を使用してください。

作業が完全に終わって、Composeが管理するコンテナとネットワークを削除したいときは、以下を実行します。

```sh
pmrails-compose down
```

名前付きボリュームはデフォルトで保持されるため、データベースのデータは通常の`down` / `up`サイクルでは保持されます。
ボリュームも削除してデータベースのデータを完全に消去したい場合は、以下を実行します。

```sh
pmrails-compose down -v
```

#### 参考: Composeの状態遷移

以下の図は、Compose環境の基本的なライフサイクルを示しています。

![Composeの状態遷移](images/compose_states.svg)

実務上のポイント:

- `up`は、「現在の設定に一致させる」ための汎用的なコマンドです。**Base (Not created)**または**Stopped**のいずれの状態からも環境を**Running**に移行させます。また、環境が既に**Running**の状態で実行しても安全です。
- `start`はより限定的です。既に作成済みで停止している環境を再開するだけで、ゼロから作り直すことはありません。設定が変更されていない場合は、`stop`と`start`を組み合わせるのが作業を一時停止・再開する最速の方法です。これは、`stop`がコンテナを削除せずにそのまま残すためです。
- `down`は、Composeが管理するコンテナとネットワークを削除することで、環境を破棄して**Base (Not created)** の状態に戻します。`-v`オプションを指定しない限り名前付きボリュームは残るため、通常の破棄を行ってもデータベースのデータは保持されます。


## 設定

PmRailsは以下の組み合わせによって設定されます。

1. **設定ファイル** — 複数のスコープに配置された`config`ファイル。
2. **呼び出し元で設定された環境変数** — 設定ファイルによって設定された内容を上書きします。
3. **カスタム`Dockerfile`** — `.pmrails/Dockerfile`（任意）。Railsコンテナイメージを制御します。
4. **カスタム`compose.yaml`** — `.pmrails/compose.yaml`（任意）。マルチコンテナ環境を記述します。

### 設定ファイル

PmRailsは4つのスコープから設定ファイルを読み込みます。存在しないファイルや読み取れないファイルは黙ってスキップされます。後のスコープが前のスコープを上書きします。

| スコープ      | パス                                                  | 典型的な用途                                              |
| ------------- | ----------------------------------------------------- | --------------------------------------------------------- |
| System        | `/etc/pmrails/config`（`PMRAILS_SYS_CONF`で上書き可） | システム管理者が設定するデフォルト                        |
| User          | `${XDG_CONFIG_HOME:-${HOME}/.config}/pmrails/config`  | このマシンでのユーザーアカウント固有のデフォルト          |
| Project       | `./.pmrails/config`                                   | プロジェクト共有の設定（Gitのコミット対象）               |
| Project-local | `./.pmrails/config.local`                             | このプロジェクトの開発者ごとの上書き設定（Gitの無視対象） |

> **ヒント:** `/etc/pmrails/config`以外のシステム設定パスを使用する場合は、`PMRAILS_SYS_CONF`環境変数を設定します（例: `export PMRAILS_SYS_CONF="/usr/local/etc/pmrails/config"`）。これは、一部のイミュータブル（不変）なディストリビューションなど、`/etc/`が読み取り専用または利用できないホストで有用です。

> **注意:** `pmrails-new-plus`はプロジェクトの`.gitignore`に`/.pmrails/var/`と`/.pmrails/config.local`の両方を追加するため、プロジェクトローカルの上書き設定はコミットされません。

#### ファイルフォーマット

各ファイルはPOSIXシェルスクリプトであり、PmRailsのエントリポイントから読み込まれます。
最も一般的な使い方は、`PMRAILS_*`変数を設定することです。例えば以下のような内容です。

```sh
# .pmrails/config
PMRAILS_PORTS="127.0.0.1:3000:3000 127.0.0.1:5000:5000"
PMRAILS_RUBY_VERSION_AT_NEW="3.4.8"
```

> **警告:** 設定ファイルは現在のシェルで直接読み込まれます（つまり実行されます）。変数設定など、信頼できる内容のみを記述してください。

### 設定用の環境変数

以下の変数は、設定ファイルへの記述、シェルでの`export`、または`pmrails-*`コマンドの前にインラインで指定（例: `PMRAILS_PORTS=127.0.0.1:8080:3000 pmrails-run bin/rails server -b 0.0.0.0`）のいずれの方法でも設定できます。

#### `:AUTO`

設定変数に`:AUTO`を設定すると、PmRailsはその変数を未設定（unset）として扱うため、通常の自動解決やデフォルト値が適用されるようになります。これは、上位の設定（システム設定やユーザー設定など）で固定値が設定されているものの、特定のプロジェクトでは自動設定の挙動に戻したいような場合に便利です。

`:AUTO`は、空文字列とは意味が異なります。`FOO=""`は明示的に空文字列を設定しますが、`FOO=":AUTO"`はPmRailsにその設定を未設定として扱わせます。

`PMRAILS_SYS_CONF`は例外で`:AUTO`をサポートしていません。これは、この変数が設定の読み込み元を制御する変数であるためです。

`:`（コロン）から始まる値は予約されています。現在は`:AUTO`のみが有効であり、その他の予約値を指定するとエラーになります。

#### `PMRAILS_RUBY_VERSION`

`pmrails-run`および`pmrails-compose`で使用されるRubyバージョンを選択します。未設定の場合、PmRailsはプロジェクトルートの`.ruby-version`からバージョンを読み取ります。詳細なルールについては、[使用するRubyバージョンの決定の仕方](#使用するrubyバージョンの決定の仕方)を参照してください。

```sh
PMRAILS_RUBY_VERSION="3.3.7"
```

#### `PMRAILS_RUBY_VERSION_SUFFIX`

`pmrails-run`および`pmrails-compose`で使用するRubyイメージタグに、任意のサフィックスを追加します。値は空文字列、または`-bookworm`や`-slim-bookworm`のように先頭の区切り文字を含む文字列である必要があります。

```sh
PMRAILS_RUBY_VERSION_SUFFIX="-bookworm"
```

例えば、`PMRAILS_RUBY_VERSION="3.3.7"`かつ`PMRAILS_RUBY_VERSION_SUFFIX="-bookworm"`の場合、`ruby:3.3.7-bookworm`が選択されます。デフォルトは空文字列です。

#### `PMRAILS_RUBY_VERSION_AT_NEW`

新しいRailsアプリケーションを**生成する**際（`pmrails-new`および`pmrails-new-plus`）に使用されるRubyバージョンを選択します。デフォルトは`latest`です。`latest`に依存するのではなく、生成時の環境を特定のRubyリリースに固定したい場合に使用します。

```sh
# `latest`の代わりにRuby 3.4.8を使用して、新しいRails 8.1アプリケーションを生成する
PMRAILS_RUBY_VERSION_AT_NEW=3.4.8 pmrails-new-plus 8.1 sample_app
```

> **注意:** プロジェクト生成時の安定性を最大化するため、これらのコマンドは常に公式の`ruby`イメージを使用し、`PMRAILS_RUBY_VERSION_SUFFIX`は意図的に無視しています。

#### `PMRAILS_PORTS`

`pmrails-run`、および`pmrails-compose`内の`rails-app`サービスの公開ポートマッピングを設定します。複数のマッピングはスペースで区切ります。

デフォルトでは、PmRailsは公開されるホスト側ポートをIPv4のループバックアドレスにバインドします。そのため、Railsはホストからはアクセスできますが、通常は他のマシンからはアクセスできません。

```sh
PMRAILS_PORTS="127.0.0.1:3000:3000"
```

よく使う例（コマンドの前にインラインで指定）:

```sh
# コンテナのポート3000をホストのポート3001に公開する（引き続きローカルのみ）
PMRAILS_PORTS="127.0.0.1:3001:3000" pmrails-run bin/rails server -b 0.0.0.0

# 別のマシンから接続する必要がある場合に、特定のLANアドレスで公開する
PMRAILS_PORTS="192.168.1.10:3001:3000" pmrails-run bin/rails server -b 0.0.0.0

# ポートを一切公開せずにコマンドを実行する
PMRAILS_PORTS= pmrails-run bin/brakeman
```

> **警告:** `3001:3000`のようにホストIPを省略すると、すべてのホストIPアドレスでポートが公開されます。ローカル開発のみで使う場合は`127.0.0.1:`を、意図的にリモートアクセスを受け付ける場合は明示的なホストIPを指定することを推奨します。

頻繁には使わないかもしれませんが、Podmanは、ポート範囲（`127.0.0.1:1234-1236:1234-1236`）、ホスト側ポートの自動割り当て（`127.0.0.1::3000`。`5000`のようにホストIPを伴わない指定では、すべてのホストIPアドレス上で自動割り当て）、複数マッピング（`"127.0.0.1:3001:3000 127.0.0.1::5000"`）にも対応しています。自動割り当てされたポートは、コンテナの実行中に`podman port <container>`で確認できます。

#### `PMRAILS_PROJECT_NAME`

プロジェクト名を上書きします。PmRailsはこの名前を`podman-compose`のプロジェクト名（`-p`フラグ）と、プロジェクト固有のイメージリポジトリ名の一部として使用します。未設定の場合、PmRailsはカレントディレクトリのベース名からプロジェクト名を導出します（小文字化し、小文字英数字とアンダースコアにサニタイズし、16文字に切り詰めます）。

> **注意:** サニタイズと16文字への切り詰めにより異なるディレクトリ名から同じプロジェクト名が導出されることがあります。ディレクトリ名が似たプロジェクトを複数扱う場合は、Composeリソースやプロジェクト固有イメージの名前の衝突を避けるため、`PMRAILS_PROJECT_NAME`を明示的に設定してください。

```sh
PMRAILS_PROJECT_NAME="sample_app"
```

#### `PMRAILS_DOCKERFILE`

プロジェクトのDockerfileへのパスです。デフォルトは`.pmrails/Dockerfile`です。ファイルが存在する場合、`pmrails-run`と`pmrails-compose`はプロジェクト固有のイメージ（`pmrails-${PMRAILS_PROJECT_NAME}`）をビルドして使用します。存在しない場合は、公式の`ruby`イメージが直接使用されます。詳細は[Railsコンテナイメージのカスタマイズ](#railsコンテナイメージのカスタマイズ)を参照してください。

#### `PMRAILS_BUILD_CONTEXT`

`podman build`へビルドコンテキストとして渡すディレクトリへのパスです。デフォルトは`.pmrails/build_context`です。Dockerfileの`COPY`と`ADD`のコピー元は、このディレクトリを基準に解決されます。

> **警告:** ビルドコンテキスト内のファイルは、通常のGit管理対象となるビルド入力であり、機密情報を含まないことを前提としています。認証情報などの機密情報はビルドコンテキスト内に置かないことを推奨します。

#### `PMRAILS_COMPOSE_FILE`

プロジェクトのCompose設定ファイルへのパスです。デフォルトは`.pmrails/compose.yaml`です。`pmrails-compose`はこのファイルが存在することを必要とし、存在しない場合はエラーで終了します。

#### `PMRAILS_GEM_HOME_ABI`

`GEM_HOME`用の共有ボリュームの名前に使われるABIサフィックスを上書きします。
この設定変数は、C言語拡張（native extension）の互換性に関わる複雑な問題へ対処するために設けられています。
ほとんどのユーザーは未設定のままで構いません。
詳細は[自動Gem共有](#自動gem共有)を参照してください。

### Railsコンテナイメージのカスタマイズ

`.pmrails/Dockerfile`が存在する場合、`pmrails-run`（および`pmrails-compose`内の`rails-app`サービス）は、公式の`ruby`イメージの代わりに、`pmrails-${PMRAILS_PROJECT_NAME}:${PMRAILS_RUBY_VERSION}${PMRAILS_RUBY_VERSION_SUFFIX}`という名前のプロジェクト固有のイメージをビルドして使用します。これにより、Railsアプリケーションが必要とするシステムパッケージ、ネイティブビルドツール、またはその他の依存関係を事前にインストールできます。

`pmrails-init`は、`--database`で選択されたデータベースエンジンに合わせた実用的なDockerfileを生成します。生成されたDockerfileは、ビルド引数として`PMRAILS_RUBY_VERSION`と`PMRAILS_RUBY_VERSION_SUFFIX`の両方を受け取り、`FROM ruby:${PMRAILS_RUBY_VERSION}${PMRAILS_RUBY_VERSION_SUFFIX}`で使用します。もちろん自分で一から書くことも可能です。

デフォルトでは、Railsプロジェクトディレクトリ全体ではなく、`.pmrails/build_context/`のみをビルドコンテキストとして使用します。`COPY`や`ADD`で必要なファイルはこのディレクトリへ置くか、必要に応じて`PMRAILS_BUILD_CONTEXT`へ別のディレクトリを設定してください。プロジェクトツリー全体を意図的にビルドへ公開する場合に限り、`.`を設定してください。その際には、`.pmrails/var/`は、認証情報やキャッシュデータを含む可能性があるため（[`.pmrails`ディレクトリの管理](#pmrailsディレクトリの管理)を参照）、機密情報とともに`.dockerignore`で除外してください。

カスタムDockerfileは、モード2とモード3の両方でオプションです。モード2では、Composeを使用せずに単一のRailsコンテナをカスタマイズできます。

Dockerfileやそのビルドコンテキストを変更した後は、以下のコマンドで変更を反映します。

```sh
pmrails-apply-dockerfile
```

このコマンドはイメージを再ビルドし、以後の`pmrails-run`で利用できるようにします。Composeの`rails-app`コンテナが既に存在する場合は、新しいイメージから再生成してCompose環境を起動します。

### Compose設定のカスタマイズ

`.pmrails/compose.yaml`が存在する場合、`pmrails-compose`はそれを内部のベースファイルと自動生成されたオーバーレイ（`rails-app`サービス用に`PMRAILS_PORTS`のマッピングを含む）の上に重ね合わせます。マージ順序は以下のとおりで、後のファイルが前のファイルを上書きします。

1. PmRailsの内部ベース（`share/compose.base.yaml`）。
2. 自動生成されたオーバーレイ。
3. ユーザーの`.pmrails/compose.yaml`。

`pmrails-init`は、選択されたデータベース用のサービス（SQLite3の場合は不要）とシステムテスト用のSeleniumサービスを含む`compose.yaml`を生成します。以下の要件を満たす限り、このファイルは自由にカスタマイズしたり、置き換えたりできます。

> **重要:** このファイルでは、ホスト側の相対パス（例: `./log`）を使用しないでください。Composeは、最初のファイル（PmRails内部のベースComposeファイル）を基準に相対パスを解決するためです。代わりに、変数展開後に絶対パスとなるように指定してください。例えば、現在のプロジェクト内のパスを指定する場合には、パスの先頭に`${PWD}`を付けてください（例: `${PWD}/log`）。

> **重要:** このファイルを変更または置き換える際には、**Railsコンテナのサービス名として必ず`rails-app`を使用してください**。PmRailsの内部コマンドや自動生成される設定は、このサービス名を前提に機能します。

> **注意:** `rails-app`サービスの`volumes`または`environment`の設定に関して、設定値を追加するのではなく、完全に上書きしてしまうと、自動Gem共有が機能しなくなる原因となります。これらをカスタマイズする必要がある場合は、`share/compose.base.yaml`を確認し、PmRails内部で必要となるマッピングを維持するようにしてください。


## `.pmrails` — ローカルディレクトリとコンテナ内の環境変数

PmRailsは、キャッシュ、設定、状態情報などのプロジェクト固有の実行時ファイルを、プロジェクトディレクトリ直下の`.pmrails/var/`というディレクトリの中で管理します。
インストール済みgemは、Podmanの名前付きボリュームで別途管理されます。詳細は[自動Gem共有](#自動gem共有)を参照してください。
また、コンテナ内で稼働するプロセスが`.pmrails/var/`内へのパスを使用するよう、各種環境変数を設定します。
この設計により、ホスト側のユーザー環境を汚さず、プロジェクトのローカル状態を簡単にリセットできます。

以下の表は、環境変数とプロジェクト内のディレクトリとの対応関係を示しています。

| 環境変数（コンテナ内） | プロジェクト内のパス（リポジトリルート基準） | 用途                                                                               |
| ---------------------- | -------------------------------------------: | ---------------------------------------------------------------------------------- |
| `HOME`                 |                          `.pmrails/var/home` | プロセスのHOME。各種ツールが、ファイル名がドット（.）で始まるファイルを書き込む。  |
| `XDG_CACHE_HOME`       |                         `.pmrails/var/cache` | ツールのキャッシュ                                                                 |
| `XDG_CONFIG_HOME`      |                        `.pmrails/var/config` | ユーザーごとの設定ファイル                                                         |
| `XDG_DATA_HOME`        |                         `.pmrails/var/share` | 一部のツールが使用する補助的なデータファイル                                       |
| `XDG_STATE_HOME`       |                         `.pmrails/var/state` | 一部のツールが使用する状態情報ファイル                                             |

### この設計の利点

- **クリーンさ:** ホストユーザーの`~/.gem`、`~/.bundle`などの個人用ファイルに影響を与えません。
- **分離性:** プロジェクトの状態がローカルに閉じるため、簡単にリセットできます。

### `.pmrails`ディレクトリの管理

- **Git:** `.pmrails/var/`はリポジトリにコミットしないでください。`pmrails-new-plus`は`.gitignore`へ`.pmrails/var/`を自動的に追加します。
- **リセット:** `.pmrails/var/`は安全に削除できます。プロジェクトローカルのキャッシュ、設定、状態情報に問題が発生した場合は、`rm -rf .pmrails/var`を実行した後、PmRailsコマンドを通常どおりに再実行してください。
- **セキュリティ:** マルチユーザー環境では、`.pmrails/`に認証情報やキャッシュデータが含まれる可能性があるため、自分以外が読み取れないようにしてください（例: `chmod -R go-rwx .pmrails`）。


## 機密情報の取り扱い

PmRails自体は、機密情報を安全に保存・管理するシークレットストアを提供しません。以下は実践的な開発指針であり、完全なセキュリティモデルを意図したものではありません。開発用の認証情報には最小権限を付与してください。平文の機密情報は、コミットしたり、画面やログへ出力したりしないでください。

### ID連携による短期認証情報を優先する

利用できる場合は、長期間有効なアクセスキーは保存せず、代わりにIDフェデレーションやSSOを利用してください。

例えば、RailsコンテナイメージにAWS CLI v2をインストールし、IAM Identity Centerのプロファイルを事前に設定します。その後、コンテナ内からサインインします。

```sh
pmrails-cmpexe aws sso login --profile my-dev
```

`.pmrails/compose.yaml`の`rails-app`サービスにある`environment`ブロックへ`AWS_PROFILE: my-dev`を追加すると、Railsは自動的にそのプロファイルを選択します。これにより、AWS SDK for Rubyはアプリケーションコードへキーを埋め込むことなく、一時的な認証情報を取得できます。

```ruby
s3 = Aws::S3::Client.new(region: "ap-northeast-1")
```

> **注意:** SSOでも機密性のあるトークンが`.pmrails/var/home/.aws/sso/cache`にキャッシュされます。このディレクトリを保護し、最小権限の開発用プロファイルを使用してください。また、適宜`pmrails-cmpexe aws sso logout`を実行してください。詳細は[AWS SDK for Rubyの認証ガイド](https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/credentials.html)を参照してください。

### ファイルベースのCompose secretsを優先する

モード3では、[Compose secrets](https://compose-spec.github.io/compose-spec/09-secrets.html)を使用することで、コンテナの環境変数やイメージに機密情報を含めずに済みます。それぞれの機密情報は、その利用を明示したサービスだけに読み取り専用ファイルとして提供されます。

```yaml
services:
  rails-app:
    environment:
      API_KEY_FILE: /run/secrets/api_key
    secrets:
    - api_key

secrets:
  api_key:
    file: "${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}/pmrails/projects/${PMRAILS_PROJECT_NAME}/secrets/api_key"
```

> **注意:** 機密情報の参照元ファイルは、ホスト上に平文で残ります。Compose secretsは暗号化された保存領域ではなく、値を読み取れるサービスを制限する機能です。

参照元ファイルはリポジトリの外に置いてください。その親ディレクトリのモードを`0700`に、ファイル自体のモードを`0600`に設定してください。SELinux環境でアクセスを拒否された場合は、[SELinuxに関する注意点](#selinuxに関する注意点)を参照してください。また、機密情報の値をコマンド引数やシェル履歴に残さないでください。

Railsは、値をプロセスの環境変数に置かず、ファイルから直接読み取れます。

```ruby
api_key = File.read(ENV.fetch("API_KEY_FILE")).chomp
```

### 必要な場合に限り`env_file`を使用する

本番プラットフォームが機密情報を環境変数として受け取る場合（Herokuなど）、モード3では`env_file`を使って同じ形式をローカルでも再現できます。envファイルはリポジトリの外に置き、その親ディレクトリのモードを`0700`に、ファイル自体のモードを`0600`に設定してください。環境変数は、コンテナの`inspect`結果、診断情報、ログなどを通じて漏えいしやすいため、可能な場合はファイルベースのCompose secretsを優先して利用してください。

```yaml
services:
  rails-app:
    env_file:
    - "${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}/pmrails/projects/${PMRAILS_PROJECT_NAME}/rails-app.env"
```

開発環境ではファイルから、本番環境では環境変数から機密情報を受け取れるようにする場合、`*_FILE`変数が未設定のときに限り、通常の環境変数へフォールバックしてください。`*_FILE`が設定されていても参照先のファイルを読み取れない場合は、別の値を暗黙的に使用せず、アプリケーションを直ちにエラー終了させてください。

```ruby
def read_secret(name)
  path = ENV["#{name}_FILE"]
  path ? File.read(path).chomp : ENV.fetch(name)
end
```

### 非機密データの保存にプロジェクトローカル領域を利用する

非機密のコードやデータを取得するためだけに認証情報が必要な場合は、ホスト上で取得し、その結果を`.pmrails/var/share/`または`.pmrails/var/home/`に保存できます。コンテナは、認証情報自体は受け取ることなく、`XDG_DATA_HOME`または`HOME`を通してその結果へアクセスできます。

> **警告:** `.pmrails/var/`を長期的な機密情報の主な保存場所にしないでください。プロジェクト外の機密情報用ディレクトリの利用を推奨します。一時的な機密情報を`.pmrails/var/`内に置く必要がある場合は、アクセス権を制限し、ビルドコンテキストやバックアップからは除外してください。また、不要になった時点で削除してください。

`.gitignore`に`.pmrails/var/`が含まれていることを確認し、なければ追加してください。ただし、`.gitignore`は、誤ってコミットすることを防ぐためのものであり、セキュリティ境界ではないことに注意してください。

### その他の事項

#### 開発チームメンバーへの配布

平文の機密情報を含むファイル（例えば`.env`ファイルなど）は絶対にコミットしないでください。機密情報をファイルやチャットメッセージで直接やり取りするのではなく、代わりに1Password CLIやAWS Secrets Manager、SOPSなどのツールを使用し、各開発者がローカルで機密情報を取得・復号するようにしてください。

#### ローカルエミュレーター

本物のクラウドへ接続する必要性がない場合は、エミュレーターの利用を推奨します。多くの主要クラウドサービスでは公式のローカルエミュレーターが提供されているため、まずそのサービスに公式ツールがないかを確認してください。なおAWSについては、有名な非公式ツールとして、[Motoのサーバーモード](https://docs.getmoto.org/en/latest/docs/server_mode.html)があります。

> **警告:** ローカルの接続先とダミーの認証情報を明示的に設定してください。本物の認証情報はエミュレーターに絶対に渡さないでください。接続情報が欠落している場合は、本物のサービスへ暗黙的にフォールバックさせることなく、エラー終了させてください。


## 自動Gem共有

PmRailsは、インストール済みgemを、`GEM_HOME`としてマウントされるPodmanの名前付きボリュームに自動的に保存します。
通常、この仕組みを意識する必要はありません。この仕組みは裏方として、繰り返し実行される`bundle install`を速くし、gemの互換性があるプロジェクト間でgemが重複して保存されることを減らします。

インストール済みgemは、以下の両方が一致する場合に再利用されます。

1. 解決されたRubyバージョン。
2. `GEM_HOME`のApplication Binary Interface（ABI）サフィックス。

`pmrails-gem_home-3.4.8`のようにABIサフィックスのないボリュームは、公式RubyイメージのABIを使用します。公式Rubyイメージだけを一貫して使っている場合は、何も意識しなくても本機能は自動的に問題なく機能します。

異なるイメージやホストプラットフォームを混在させる場合の基本ルールは、**ABIサフィックスが同じであれば、C言語拡張（native extension）の互換性が必ずある**ようにすることです。

`PMRAILS_GEM_HOME_ABI`が未設定の場合、PmRailsはイメージタグからABIサフィックスを自動的に導出します。具体的には、先頭の数値のRubyバージョン部分とその直後の`-`があればそれらを取り除きます。そしてそれ以外の文字列は、互換性のないgemストアを過度にまとめないように残します。例えば、`3.4.8-trixie`は`trixie`になります。

つまり、`PMRAILS_RUBY_VERSION_SUFFIX="-bookworm"`を設定すると、通常は共有`GEM_HOME`ボリュームにもABIサフィックス`bookworm`が付きます。

もしこの自動導出が用途や目的に合わない場合や、gemストアを手動で分割・統合したい場合は、設定ファイルでこの値を上書きしてください。

```sh
# .pmrails/config

# 特定のABIサフィックスを使用する
PMRAILS_GEM_HOME_ABI="alpine3.22"

# または、サフィックスなしの公式RubyイメージABIボリュームを使用する
PMRAILS_GEM_HOME_ABI=""
```

これらのgemストアの管理には`podman volume`を使用します。`podman volume ls`で一覧を見られます。リセットするには対象のボリュームを以下のように削除します。

```sh
podman volume rm pmrails-gem_home-3.4.8-trixie
```

すでに使用しているRubyバージョンにおいて、公式RubyイメージのABIに変更があった場合は、C言語拡張を含むgemが再ビルドされるよう、そのRubyバージョンのサフィックスなしボリュームを削除してください。


## 使用するRubyバージョンの決定の仕方

PmRailsは、カレントディレクトリにある`.ruby-version`ファイルの有無と内容に基づいて、使用するRubyバージョンを決定します。

### `.ruby-version`を参照するコマンド

以下のコマンドは、`.ruby-version`を読んでRubyバージョンを決定します。

- `pmrails-run`
- `pmrails-compose`

（`pmrails-new`および`pmrails-new-plus`は、生成対象のプロジェクト自体がまだなく、当然`.ruby-version`も存在しないため、代わりに`PMRAILS_RUBY_VERSION_AT_NEW`を使用します。）

### `.ruby-version`の有無による挙動の違い

- **`.ruby-version`が有る場合:**
  ファイルの1行目からRubyバージョンを抽出し、対応するコンテナイメージを使用します。

- **`.ruby-version`が無い場合:**
  イメージタグのRubyバージョン部分として`latest`をデフォルトとして使用します。

### 対応するバージョン記述

PmRailsは`.ruby-version`の**1行目**に含まれる`MAJOR.MINOR.PATCH`形式のバージョン文字列を探し、
最初に見つかったものを使用します。

対応している記述例:

- `3.2.2`
- `ruby-4.0.1`（数値部分の`4.0.1`が抽出されます）

1行目に`MAJOR.MINOR.PATCH`形式の文字列が見つからない場合、コマンドはエラーで終了します。
コンテナイメージの選択において曖昧さを無くし、再現性を保つために、このような仕様にしています。

### コンテナイメージとの関係

`.ruby-version`から抽出した文字列は、コンテナイメージタグのRubyバージョン部分として使用されます。PmRailsは、設定されている場合にはさらに`PMRAILS_RUBY_VERSION_SUFFIX`を付け加えます。

> `ruby:<major.minor.patch><PMRAILS_RUBY_VERSION_SUFFIX>`

デフォルトのサフィックスなしの場合:

> `.ruby-version`: `3.2.2` -> `ruby:3.2.2`

`PMRAILS_RUBY_VERSION_SUFFIX="-bookworm"`の場合:

> `.ruby-version`: `3.2.2` -> `ruby:3.2.2-bookworm`

PmRailsは、バージョンの正規化や互換性チェックは行いません。

### Rubyバージョンの変更

`.ruby-version`内のバージョンを変更すると、PmRailsが使用するコンテナイメージも切り替わります。

共有`GEM_HOME`ボリュームはRubyバージョンごとに分かれるため、Rubyバージョンを変更した場合、通常はインストールされるgemも自動的に分離されます。イメージやプラットフォームのABIも変化する場合については、[自動Gem共有](#自動gem共有)を参照してください。

バージョン変更後にキャッシュ、設定、または状態ファイルが原因で問題が発生した場合でも、`.pmrails/var/`内のプロジェクトローカルな状態は安全に削除（リセット）することができます。

> **ヒント:** 設定ファイルや環境変数で`PMRAILS_RUBY_VERSION`を設定することで、決定されるバージョンを明示的に上書きすることもできます。詳細は[設定用の環境変数](#設定用の環境変数)を参照してください。


## 外部データベースの利用

PmRailsは、「ホスト上で動作しているデータベース」または「ホストで別に稼働しているデータベース用コンテナ」に接続することができます。
PmRailsコンテナ内で稼働しているRailsからこのようなホスト側のデータベースへ接続する簡便な方法の一つが、`host.containers.internal`を利用する方法です。

ここでは例としてPostgreSQLを用いますが、以下の方針は基本的に他のデータベースにも適用できます。

1. `-p`オプションでポートを公開したうえで、ホストでデータベース用コンテナを起動する。
2. `database.yml`において、適切なアダプタと認証情報、さらに`host: host.containers.internal`を設定する。

### PostgreSQLサーバーを起動する例

ホスト上のコンテナでPostgreSQLを起動します。

```sh
podman run -d --name postgres -p 5432:5432 -e POSTGRES_PASSWORD=your_password postgres:latest
```

### `config/database.yml`の例

`host.containers.internal`を利用して、Railsアプリケーションのデータベースアクセスをホスト上のデータベースへ差し向けます。

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: sample_app_development
  username: postgres
  password: your_password
  host: host.containers.internal

test:
  <<: *default
  database: sample_app_test
  username: postgres
  password: your_password
  host: host.containers.internal
```

`config/database.yml`を編集した後、通常どおりPmRailsのコマンド（例: `pmrails-run bin/rails db:create`、`pmrails-run bin/rails server -b 0.0.0.0`）を実行してください。PmRailsコンテナ内のRailsプロセスは、ホスト上で別に稼働しているコンテナ内のPostgreSQLサーバーに接続します。

### 参考: postgresコンテナの停止/起動/削除

ホスト上のPostgreSQLコンテナを管理するためによく使われるコマンドは以下のとおりです。

```sh
# postgresコンテナを停止
podman stop postgres

# postgresコンテナを起動（再開）
podman start postgres

# postgresコンテナを削除（削除前に停止が必要）
podman rm postgres
```

> **注意:** データベースをRailsアプリケーションと同じCompose環境の一部として稼働させたい場合は、[モード3: Composeを使った作成と開発](#3-composeを使った作成と開発)を参照してください。


## 制限事項

PmRailsは、軽量かつ動作が予測しやすいPodmanラッパーとして設計されています。
単純さと透明性を保つため、PmRailsにはいくつかの前提やトレードオフが存在します。

### セキュリティサンドボックスとしては使用不可

PmRailsは開発用の依存関係を隔離するためにコンテナを使用しますが、信頼できないコードを安全に実行するためのセキュリティサンドボックスでは**ありません**。悪意のある攻撃を封じ込められる設計にはなっていません。信頼できないリポジトリの評価にはPmRailsは使用せず、代わりに使い捨てのVMを利用してください。

### SELinuxに関する注意点

SELinuxが有効になっているシステムでは、マウントされたホストのディレクトリがコンテナ内から書き込み不可になることがあります。

- PmRailsは、Railsプロジェクトディレクトリのマウントに対して`:z`や`:Z`のオプションを自動的には付与しません。
- PmRailsは、自身の補助的なマウント（読み取り専用のPmRailsエントリポイントやライブラリのマウントなど）にSELinuxのリラベル（ラベルの付け直し）を適用する場合があります。
- プロジェクトファイルへのアクセスが拒否される場合、SELinuxのコンテキストを、`chcon`で一時的に調整するか、`semanage`と`restorecon`で永続的に調整してください。
- これは、SELinuxのセキュリティポリシーが知らない間に弱められることを避けるための意図的な仕様です。


## コントリビューション

[コントリビューションガイド](CONTRIBUTING.md)を参照してください。
