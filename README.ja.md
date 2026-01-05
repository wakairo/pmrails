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

- **`pmrails`**: `bin/rails`のラッパーとして、Railsコマンドを実行します。\
  **使用方法**: `pmrails COMMAND [OPTIONS]`

- **`pmrails-new`**: `rails new`のラッパーとして、新しいRailsアプリケーションを作成します。\
  **使用方法**: `pmrails-new RAILS_VERSION APP_PATH [OPTIONS]`

- **`pmrails-new-plus`**: PmRailsを用いた新しいRailsアプリケーションの開発のための典型的なセットアップを一度に行います。\
  **使用方法**: `pmrails-new-plus RAILS_VERSION APP_PATH [OPTIONS]`

- **`pmrailsenvexec`**: コンテナ環境内で任意のコマンドを実行します。\
  **使用方法**: `pmrailsenvexec COMMAND [OPTIONS]`

- **`pmbundle`**: `bundle`のラッパーとして、gemを管理します。\
  **使用方法**: `pmbundle [BUNDLE_ARGS]`


## インストール

### 事前準備

Podmanが必要です。
[Podmanインストール手順](https://podman.io/docs/installation)の中からお使いのOS用の手順に従ってください。

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
echo 'export PATH="$HOME/.var/pmrails/bin/:$PATH"' >> ~/.bashrc
exec $SHELL -l
```


## 使用方法

PmRailsには主に2つの使い方があります。

1. **新しいRailsアプリケーションの作成のみ** — コンテナ内で`rails new`を実行します。
2. **Railsアプリケーションの作成と開発** — アプリケーション作成時に`.pmrails/var/bundle/`にgemをインストールし、PmRailsツールセットで開発を行います。

### 1. 新しいRailsアプリケーションの作成のみ

アプリケーションの初期生成のみPmRailsで行い、開発等は別環境で行う場合には、こちらの使い方をご利用ください。
`pmrails-new`は`rails new`と同じように振る舞います。

一時ディレクトリに移動します。例えば、以下のように作成して移動します。

```sh
mkdir -p ~/tmp
cd ~/tmp
```

以下の例のように、使用したいRailsバージョンと`rails new`のオプションを指定して新しいRailsアプリを作成します。

```sh
pmrails-new 8.1 new_app --database=postgresql
```

### 2. Railsアプリケーションの作成と開発

PmRailsで開発も行う場合にはこちらの使い方をご利用ください。
gemはローカルの`.pmrails/var/bundle/`ディレクトリにインストールされるため、
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

なお、`pmrails-new-plus`ではアプリケーション名の後に`rails new`のオプションを指定できます。

また、`pmrails-new-plus`は以下の処理を自動で実行します。

* 新しいRailsアプリケーションを作成する
* `.pmrails/var/bundle/`にgemをインストールする
* `.gitignore`に`.pmrails/var/`を追加する

#### Railsのコマンドの実行

作成したアプリケーションのディレクトリに移動します。

```sh
cd sample_app
```

Railsのコマンドを実行するには`pmrails`を使用します。
例えばサーバーを起動するには、以下のコマンドを実行します。

```sh
pmrails server -b 0.0.0.0
```

サーバーが立ち上がったら、ウェブブラウザで`http://localhost:3000/`にアクセスします。

#### その他のコマンドの実行例

```sh
# bundleによるgemのインストールの実行
pmbundle install

# データベースのマイグレーションの実行
pmrails db:migrate

# テストの実行
pmrails test

# Railsコンソールの開始
pmrails console

# Railsのセットアップスクリプトの実行
pmrailsenvexec bin/setup
```


## `.pmrails` — ローカルディレクトリと環境変数

PmRailsは、実行時に用いるファイル（gem、キャッシュ、設定、状態情報など）をプロジェクトごとにプロジェクトディレクトリ直下の`.pmrails/var/`というディレクトリの中でまとめて管理します。
また、コンテナ内で稼働するプロセスが`.pmrails/var/`内へのパスを使用するよう、各種環境変数を設定します。
この設計により、ホスト側のユーザー環境を汚さず、プロジェクトを自己完結した状態に保つことができます。

以下の表は、環境変数とプロジェクト内のディレクトリとの対応関係を示しています。

| 環境変数（コンテナ内）| プロジェクト内のパス（リポジトリルート基準） | 用途                                                                               |
| --------------------- | -------------------------------------------: | ---------------------------------------------------------------------------------- |
| `HOME`                |                          `.pmrails/var/home` | プロセスの HOME。各種ツールが、ファイル名がドット（.）で始まるファイルを書き込む。 |
| `XDG_CACHE_HOME`      |                         `.pmrails/var/cache` | ツールのキャッシュ                                                                 |
| `XDG_CONFIG_HOME`     |                        `.pmrails/var/config` | ユーザーごとの設定ファイル                                                         |
| `XDG_DATA_HOME`       |                         `.pmrails/var/share` | 一部のツールが使用する補助的なデータファイル                                       |
| `XDG_STATE_HOME`      |                         `.pmrails/var/state` | 一部のツールが使用する状態情報ファイル                                             |
| `BUNDLE_PATH`         |                        `.pmrails/var/bundle` | Bundlerによるgemのインストール先（プロジェクトが用いるgem）                        |

### この設計の利点

* **クリーンさ:** ホストユーザーの `~/.gem`、`~/.bundle` などの個人用ファイルに影響を与えません。
* **分離性:** プロジェクトの状態がローカルに閉じるため、簡単にリセットできます。

### `.pmrails` ディレクトリの管理

* **Git:** `.pmrails/var/`はリポジトリにコミットしないでください。`pmrails-new-plus`は`.gitignore`へ`.pmrails/var/`を自動的に追加します。
* **リセット:** `.pmrails/var/`は安全に削除できます。問題が発生した場合は、`rm -rf .pmrails/var`を実行した後に`pmbundle install`を行うことで環境を再構築できます。
* **セキュリティ:** マルチユーザー環境では、`.pmrails/`に認証情報やキャッシュデータが含まれる可能性があるため、自分以外が読み取れないようにしてください（例: `chmod -R go-rwx .pmrails`）。


## 使用するRubyバージョンの決定の仕方

PmRailsは、カレントディレクトリにある`.ruby-version`ファイルの有無と内容に基づいて、使用するRubyのバージョンを決定します。

### `.ruby-version`を参照するコマンド

以下のコマンドは、`.ruby-version`を読んでRubyバージョンを決めます。

- `pmbundle`
- `pmrails`
- `pmrailsenvexec`

### `.ruby-version`の有無による挙動の違い

- **`.ruby-version`が有る場合:**
  ファイルの1行目からRubyバージョンを抽出し、対応するコンテナイメージを使用します。

- **`.ruby-version`が無い場合:**
  `ruby:latest`をデフォルトとして使用します。

### 対応するバージョン記述

PmRailsは`.ruby-version`の**1行目**に含まれる`MAJOR.MINOR.PATCH`形式のバージョン文字列を探し、
最初に見つかったものを使用します。

対応している記述例：

- `3.2.2`
- `ruby-4.0.1`（数値部分の `4.0.1` が抽出されます）

1行目に`MAJOR.MINOR.PATCH`形式の文字列が見つからない場合、コマンドはエラーで終了します。
コンテナイメージの選択において曖昧さを無くし、再現性を保つために、このような仕様にしています。

### コンテナイメージとの関係

`.ruby-version`から抽出した文字列は、そのままコンテナイメージのタグとして使用されます。

> `ruby:<major.minor.patch>`

例：

> `.ruby-version`: `3.2.2` -> `ruby:3.2.2`

PmRailsは、バージョンの正規化や互換性チェックは行いません。

### Rubyバージョンの変更

`.ruby-version`内のバージョンを変更すると、PmRailsが使用するコンテナイメージも切り替わります。

その際、`.pmrails/var/`内にある既存のローカルデータ（インストール済みgemなど）が互換性を失う場合があります。
問題が発生した場合は、`.pmrails/var/`ディレクトリを削除し、gemを再インストールすることで通常は解決します。


## 外部データベースの利用

PmRailsは、「ホスト上で動作しているデータベース」または「ホストで別に稼働しているデータベース用コンテナ」に接続することができます。
PmRailsコンテナ内で稼働しているRailsからこのようなホスト側のデータベースへ接続する簡便な方法の一つが、`host.containers.internal`を利用する方法です。

以下では例としてPostgreSQLを用いますが、以下の方針は基本的に他のデータベースにも適用できます。

1. `-p`オプションでポートを公開したうえで、ホストでデータベース用コンテナを起動する。
2. `database.yml`において、適切なアダプタと認証情報、さらに`host: host.containers.internal`を設定する。

### PostgreSQLサーバーを起動する例

ホスト上のコンテナでPostgreSQLを起動します。

```sh
podman run -d --name postgres -p 5432:5432 -e POSTGRES_PASSWORD=your_password postgres:latest
```

### `config/database.yml` の例

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

`config/database.yml`を編集した後、通常どおりPmRailsのコマンド（例: `pmrails db:create`、`pmrails server -b 0.0.0.0`）を実行してください。
PmRailsコンテナ内のRailsプロセスは、ホスト上で別に稼働しているコンテナ内のPostgreSQLサーバに接続します。

### 参考: postgresコンテナの停止/起動/削除

ホスト上のPostgreSQLコンテナを管理するためによく使われるコマンドは以下の通りです。

```sh
# postgresコンテナを停止
podman stop postgres

# postgresコンテナを起動（再開）
podman start postgres

# postgresコンテナを削除（削除前に停止が必要）
podman rm postgres
```


## 制限事項

PmRailsは、軽量かつ動作が予測しやすいPodmanラッパーとして設計されています。
単純さと透明性を保つため、PmRailsにはいくつかの前提やトレードオフが存在します。

### 固定されたポートフォワーディング

`pmrails`と`pmrailsenvexec`コマンドは、デフォルトでコンテナの **3000番ポート**をホストにフォワーディングします。

* Railsのdevelopmentサーバーのデフォルトポートに合わせています。
* ホスト側でポート3000が既に使用されている場合、これらのコマンドは失敗します。
* 現時点では、カスタムのポートマッピングはサポートされていません。

### 新規アプリ生成では`ruby:latest`を使用

`pmrails-new`と`pmrails-new-plus`は、常に`ruby:latest`コンテナイメージを使用します。

* `latest`が指すRubyバージョンは時が経つにつれ変化します。
* アプリ生成時の環境と、後から`.ruby-version`で指定される実行環境が一致しない場合があります。

### SELinuxに関する注意点

SELinuxが有効になっているシステムでは、マウントされたホストのディレクトリがコンテナ内から書き込み不可になることがあります。

* PmRailsは`:z`や`:Z`のマウントオプションを自動的には付与しません。
* アクセスが拒否される場合、ユーザー自身でSELinuxのコンテキストを調整する必要があります（例: `chcon`）。
* SELinuxのセキュリティポリシーを知らない間に弱められないように意図的にこのようになっています。
