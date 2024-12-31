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

PmRailsは以下のコマンドを提供します:

- **`pmrails`**: `bin/rails`のラッパーとしてRailsコマンドを実行します。\
  **使用方法**: `pmrails COMMAND [OPTIONS]`

- **`pmrails-new`**: `bin/rails new`のラッパーとして、新しいRailsアプリケーションを作成します。\
  **使用方法**: `pmrails-new RAILS_VERSION APP_PATH [OPTIONS]`

- **`pmrailsenvexec`**: コンテナ環境内で任意のコマンドを実行します。\
  **使用方法**: `pmrailsenvexec COMMAND [OPTIONS]`

- **`pmbundle`**: `bundle`のラッパーとして、Gemを管理します。\
  **使用方法**: `pmbundle [BUNDLE_ARGS]`\
  Gemは`vendor/bundle/`ディレクトリにインストールされ、`pmrails`で使用されます。

Gem環境をリセットするには、単に`vendor/bundle/`ディレクトリを削除してください:


```sh
rm -rf vendor/bundle/
```

## インストール

### 事前準備: Podmanのインストール

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

### 新しいRailsアプリケーションの作成

一時ディレクトリに移動します。例えば、以下のように作成と移動を行います。

```sh
mkdir -p ~/tmp
cd ~/tmp
```

以下の例のように、使用したいRailsバージョンで新しいRailsアプリを作成します。

```sh
pmrails-new 8.0.1 sample_app --skip-bundle
```

作成したアプリケーションのディレクトリに移動します。

```sh
cd sample_app
```

Bundlerを実行してGemをインストールします。

```sh
pmbundle install
```

アプリ開発でGitを使用する場合は、以下の例のような方法で、`.gitignore`へ`/vendor/bundle/`を追加します。

```sh
echo /vendor/bundle/ >> .gitignore
```

### Railsのコマンドの実行

Railsのコマンドを実行するにはpmrailsを使用します。
例えばサーバーを起動するには、以下のコマンドを実行します。

```sh
pmrails server -b 0.0.0.0
```

サーバーが立ち上がったら、ウェブブラウザで`http://localhost:3000/`にアクセスします。

以下は、PmRailsを使用したその他のコマンドの実行例です。

```sh
# データベースのマイグレーションの実行
pmrails db:migrate

# テストの実行
pmrails test

# Railsコンソールの開始
pmrails console

# Railsのセットアップスクリプトの実行
pmrailsenvexec bin/setup
```
