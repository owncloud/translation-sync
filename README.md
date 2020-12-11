# Translation Sync

[![Build Status](https://drone.owncloud.com/api/badges/owncloud/translation-sync/status.svg)](https://drone.owncloud.com/owncloud/translation-sync)

Within this repository we define a DroneCI configuration to sync Transifex translations every night for different repositories. If you want to get automated translation sync for your app as well please file a pull request to this repository and add [ownclouders](https://github.com/ownclouders) with write permissions to your repository.

# Local testing

You can test the synchronisation of translations for a specific repo by cloning the repo into your checkout of this repo and running `drone exec` like this:

```
git clone https://github.com/owncloud/web.git
TX_TOKEN=... REPO_NAME=owncloud_universal REPO_URL=https://github.com/owncloud/web.git REPO_GIT=git@github.com:owncloud/web.git REPO_BRANCH=master REPO_PATH=web MODE=MAKE drone exec --local --build-event push
```

The trick is to prepend the folder to which the repo was cloned to the `REPO_PATH`.

You can generate a Transifex token here: https://www.transifex.com/user/settings/api/ for the `TX_TOKEN` env var.

## Issues, Feedback and Ideas

Open an [Issue](https://github.com/owncloud/translation-sync/issues)


## Contributing

Fork -> Patch -> Push -> Pull Request


## Authors

* [Thomas Boerger](https://github.com/tboerger)


## License

MIT


## Copyright

```
Copyright (c) 2018 Thomas Boerger <tboerger@owncloud.com>
```
