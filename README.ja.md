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
2. **Railsアプリケーションの作成と開発** — アプリケーション作成時に`vendor/bundle/`にgemをインストールし、PmRailsツールセットで開発を行います。

### 1. 新しいRailsアプリケーションの作成のみ

アプリケーションの初期生成はPmRailsで行うが開発等は別環境で行う場合にはこちらの使い方をご利用ください。
`pmrails-new`は`rails new`と同じように振る舞います。

一時ディレクトリに移動します。例えば、以下のように作成と移動を行います。

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
gemはローカルの`vendor/bundle/`ディレクトリにインストールされるため、
ホスト側のRuby環境に影響を与えずに開発を行えます。

> **注意:** 現行では、PmRailsで開発する場合、developmentとtestのデータベースとして **SQLite** の利用が想定されています。

#### `pmrails-new-plus`を利用した新しいRailsアプリケーションの作成

一時ディレクトリに移動します。例えば、以下のように作成と移動を行います。

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
* `vendor/bundle/`にgemをインストールする
* `.gitignore`に`vendor/bundle/`を追加する

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


## Tips

### gem環境のリセット

gem関連のエラーが発生した場合、ローカルのbundleディレクトリをリセットすると問題が解決する場合があります。
リセットするには、以下のように単純に`vendor/bundle/`ディレクトリを削除してください。

```sh
rm -rf vendor/bundle/
```

ディレクトリを削除したら、以下のように再度gemをインストールします。

```sh
pmbundle install
```
