# GitHub Migration Analyzer

Migration Analyzerは、GitHubへのリポジトリ移行を計画し、移行規模を測定するのに役立つコマンドライン（CLI）ユーティリティツールです。このツールは現在、Azure DevOpsおよびGitHub Cloudをソースとし、GitHub Cloudを移行先とする移行をサポートしています。

このツールは、GitHubのEnterprise Importer（GEI）と併用するためのものです。お客様がGEI自体でドライラン移行を実行することなく、移行する必要があるデータ量を測定するためのセルフサービスツールです。

## 環境要件

このツールは[Node.js](https://nodejs.org/)ランタイム環境で動作します。バージョン14以上が必要です。

## インストール

コマンド ```cd <任意の親ディレクトリのパス> && git clone https://github.com/github/gh-migration-analyzer.git``` を使用して、任意の親ディレクトリに移動し、ツールをインストールします。

## Personal Access Tokens

ソース（Azure DevOpsまたはGitHub）内でPersonal Access Token（PAT）を生成する必要があります。以下のスコープが必要です。

* Azure DevOpsの場合：`Code`に対する`read`権限
* GitHub Cloudの場合：`repo`権限

## 依存関係

コマンド ```cd <migration analyzerディレクトリのパス> && npm install``` を使用して```migration-analyzer```ディレクトリに移動します。これにより、以下のプロジェクト依存関係がインストールされます：

- [commander](https://www.npmjs.com/package/commander)
- [csv-writer](https://www.npmjs.com/package/csv-writer)
- [node-fetch](https://www.npmjs.com/package/node-fetch)
- [ora](https://www.npmjs.com/package/ora)
- [p-limit](https://www.npmjs.com/package/p-limit)
- [prompts](https://www.npmjs.com/package/prompts)

## 使用方法

ツールの使用方法に関する情報は、helpコマンドで確認できます。
````
node src/index.js help
````

Azure DevOps組織のメトリクスを取得してCSVに書き出します。
````
node src/index.js ADO-org [オプション]

オプション:
  -p, --project <プロジェクト名> Azure DevOpsプロジェクト名（プロジェクトまたは組織のいずれかを渡すことができ、両方を渡す必要はありません）
  -o, --organization <組織> Azure DevOps組織名
  -t, --token <PAT> Azure DevOps personal access token
  -h, --help Azure DevOpsオプションのヘルプコマンド
````

GitHub組織のメトリクスを取得してCSVに書き出します
````
node src/index.js GH-org [オプション]

オプション:
  -o, --organization <組織> GitHub組織名（必須）
  -t, --token <PAT> GitHub personal access token
  -s, --server <GRAPHQL URL> GHESインスタンスのGraphQLエンドポイント
  -a, --allow-untrusted-ssl-certificates 信頼できるCAによって発行されていないSSL証明書を提示するGitHub APIエンドポイントへの接続を許可
  -h, --help GitHubオプションのヘルプコマンド

````

コマンドでPATを渡したくない場合は、代わりに環境変数としてPATをエクスポートすることもできます。

````export GH_PAT=<PAT>```` または ````export ADO_PAT=<PAT>````

ツールは、プロジェクトのルートディレクトリ内の新しいディレクトリにCSVファイルをエクスポートします。GitHubがソースの場合、ツールは2つのCSVファイルをエクスポートします。
- 1つはプルリクエスト、イシュー、プロジェクトの数、およびwikiが有効かどうかを含むリポジトリのリスト。
- もう1つは組織レベルの集計メトリクス（リポジトリ、プルリクエスト、イシュー、プロジェクトの数）を含みます。Azure DevOpsがソースの場合、CSVには各プロジェクト、および各プロジェクト内のリポジトリとプルリクエストがリストされます。

**PowerShell版について**

PowerShell版を利用する場合は以下のコマンドレットを利用してください。
```
.\src\powershell\custumize_v3.ps1 GitHub組織名（必須）
```

## GitHub Enterprise Server（GHES）での使用方法

このツールは、GHES 3.4以降に対して実行して移行統計を収集できます。GHESインスタンスのWebポータルにアクセスできるコンピューターにこのリポジトリをクローンしてください。このREADMEで前述したインストール手順を実行していることを確認してください。`-s`オプションでGHESインスタンスのGraphQLエンドポイントを指定する必要があります。このエンドポイントの取得方法については、GitHubが提供する[GraphQLでの呼び出しの形成](https://docs.github.com/en/enterprise-server@3.4/graphql/guides/forming-calls-with-graphql#the-graphql-endpoint)ドキュメントで学習できます。最終的なコマンドは以下の例のような構造になります。

```
node src/index.js GH-org -o <組織名> -s <GHES GraphQLエンドポイント>
```

## 貢献

このアプリケーションは、元々Aryan Patel（[@arypat](https://github.com/AryPat)）とKevin Smith（[@kevinmsmith131](https://github.com/kevinmsmith131)）によって書かれました。参加方法の詳細については、[Contributing](CONTRIBUTING.md)をご覧ください。

## サポート
これは*GitHubサポートによってサポートされていない*コミュニティプロジェクトです。

ヘルプが必要な場合は、[issue](https://github.com/github/gh-migration-analyzer/issues)を通してコミュニティと交流してください。PRはいつでも歓迎です！