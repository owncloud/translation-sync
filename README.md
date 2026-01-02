# Translation Sync

[![Build Status](https://drone.owncloud.com/api/badges/owncloud/translation-sync/status.svg)](https://drone.owncloud.com/owncloud/translation-sync)

Within this repository, we define a DroneCI configuration to sync Transifex translations every night (or triggered manually) for different repositories. This is required because you need elevated Transifex permissions which are proveded by drone secrets only. If you want to get automated translation sync for your app as well please file a pull request to this repository and add [ownclouders](https://github.com/ownclouders) with write permissions to your repository.

**Table of Contents**

   * [Local Testing](#local-testing)
      * [Pull new Translations for the Guests Apps](#pull-new-translations-for-the-guests-apps)
   * [Push Translations for Web](#push-translations-for-web)
   * [Migrate Resources](#migrate-resources)
   * [Trigger Syncing Manually](#trigger-syncing-manually)
   * [License](#license)
   * [Copyright](#copyright)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->

## Local Testing

You can test the synchronisation of translations for a specific repo by cloning the repo into your checkout of this repo and running `drone exec` like this:

### Pull new Translations for the Guests Apps

Normally the pull is done every 24h automatically. You can do the pull manually with

```Shell
app=guests
grep $app .drone.star
        repo(name = "guests", mode = "old"),
```

If the mode is old, then

```Shell
git clone git@github.com/owncloud/$app
cd $app
export TX_TOKEN=...
tx pull -a --skip --minimum-perc=75 -f
# Now we have many subdirectories with *.po files. The l10n script in owncloud-ci/transifex creates *.js and *.json from there.
txdockerrun() { docker run -ti -v $(pwd):/mnt -w /mnt --entrypoint=/bin/bash owncloudci/transifex:latest -c "set -x; $@"; }
txdockerrun "cd l10n; l10n '$app' write"

find . -name *.po -type f -delete
rmdir ?? ??_??

# review the changes
git diff
```

## Push Translations for Web

```Shell
git clone https://github.com/owncloud/web.git
TX_TOKEN=... REPO_NAME=owncloud_universal REPO_URL=https://github.com/owncloud/web.git REPO_GIT=git@github.com:owncloud/web.git REPO_BRANCH=master REPO_PATH=web MODE=MAKE drone exec --local --build-event push
```

The trick is to prepend the folder to which the repo was cloned to the `REPO_PATH`.

You can generate a [Transifex token](https://www.transifex.com/user/settings/api/) for the `TX_TOKEN` env var.

## Migrate Resources

Follow the [step-by-step](docs/migrate.md) guide if the relocation of resources is required.

## Trigger Syncing Manually

If there is a manual “emergency” sync required, you only need to trigger [drone](https://drone.owncloud.com/owncloud/translation-sync) via the CLI:

```bash
drone cron exec owncloud/translation-sync nightly
```

Note that you need to be logged on in drone to execute the command.

## License

MIT

## Copyright

```Plain
Copyright (c) 2022 ownCloud GmbH
```
