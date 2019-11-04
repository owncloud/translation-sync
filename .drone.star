def main(ctx):
    repo_pipelines = [
        repo(name = "core", path = "l10n"),
        repo(name = "activity", mode = "old"),
        repo(name = "announcementcenter", mode = "old"),
        repo(name = "brute_force_protection", mode = "old"),
        repo(name = "calendar", mode = "old"),
        repo(name = "contacts", mode = "old"),
        repo(name = "customgroups", mode = "old"),
        repo(name = "diagnostics", mode = "old"),
        repo(name = "external", mode = "old"),
        repo(name = "files_antivirus", mode = "old"),
        repo(name = "files_external_dropbox", mode = "old"),
        repo(name = "files_external_ftp", mode = "old"),
        repo(name = "files_external_gdrive", mode = "old"),
        repo(name = "files_paperhive", mode = "old"),
        repo(name = "files_texteditor", mode = "old"),
        repo(name = "firstrunwizard", mode = "old"),
        repo(name = "guests", mode = "old"),
        repo(name = "impersonate", mode = "old"),
        repo(name = "notes", mode = "old"),
        repo(name = "notifications", mode = "old"),
        repo(name = "oauth2", mode = "old"),
        repo(name = "password_policy", mode = "old"),
        repo(name = "richdocuments", mode = "old"),
        repo(name = "tasks", mode = "old"),
        repo(name = "templateeditor", mode = "old"),
        repo(name = "twofactor_backup_codes", mode = "old"),
        repo(
            name = "twofactor_privacyidea",
            url = "https://github.com/privacyidea/privacyidea-owncloud-app.git",
            git = "git@github.com:privacyidea/privacyidea-owncloud-app.git",
            path = "./twofactor_privacyidea",
            mode = "old",
        ),
        repo(name = "twofactor_totp", mode = "old"),
        repo(name = "user_ldap", mode = "old"),
        repo(name = "user_management", mode = "old"),
        repo(name = "encryption", mode = "old"),
        repo(name = "phoenix", mode = "old"),
        repo(
            name = "windows_phone",
            url = "https://github.com/owncloud/OwncloudUniversal.git",
            git = "git@github.com:owncloud/OwncloudUniversal.git",
            mode = "old",
        ),
        repo(
            name = "ios-app",
            ref = "translation-sync",
            mode = "native",
        ),
        repo(
            name = "ios-sdk",
            ref = "translation-sync",
            mode = "native",
        ),
        repo(
            name = "ios-old",
            url = "https://github.com/owncloud/ios.git",
            git = "git@github.com:owncloud/ios.git",
            mode = "native",
        ),
        repo(
            name = "android",
            mode = "native",
        ),
    ]

    repo_pipeline_names = []
    for repo_pipeline in repo_pipelines:
        repo_pipeline_names.append(repo_pipeline["name"])

    return repo_pipelines + [notification(depends_on = repo_pipeline_names)]

def repo(name, url = "", git = "", path = ".", ref = "master", mode = "make"):
    url = url if url != "" else "https://github.com/owncloud/" + name + ".git"
    git = git if git != "" else "git@github.com:owncloud/" + name + ".git"
    sub_path = "l10n" if mode == "old" else "."

    return {
        "kind": "pipeline",
        "type": "docker",
        "name": name,
        "platform": {
            "os": "linux",
            "arch": "amd64",
        },
        "clone": {
            "disable": True,
        },
        "steps": [
            # clone
            {
                "name": "clone",
                "image": "plugins/git:1",
                "pull": "always",
                "settings": {
                    "tags": False,
                    "recursive": False,
                    "remote": url,
                    "ref": ref,
                    "sha": "FETCH_HEAD",
                },
            },

            # translation-directory
            {
                "name": "translation-directory",
                "image": "owncloudci/transifex:latest",
                "pull": "always",
                "environment": {
                    "TX_TOKEN": from_secret("tx_token"),
                },
                "commands": [
                    "mkdir -p '" + path + "/" + sub_path + "'",
                ] if mode == "old" else ["echo 'noop'"],
            },

            # translation reader
            {
                "name": "translation-reader",
                "image": "owncloudci/transifex:latest",
                "pull": "always",
                "environment": {
                    "TX_TOKEN": from_secret("tx_token"),
                },
                "commands": [
                    "cd '" + path + "'",
                    "make l10n-read",
                ],
            } if mode == "make" else {
                "name": "translation-reader-old",
                "image": "owncloudci/transifex:latest",
                "pull": "always",
                "environment": {
                    "TX_TOKEN": from_secret("tx_token"),
                },
                "commands": [
                    "cd '" + path + "/" + sub_path + "'",
                    "l10n '" + name + "' read",
                ] if mode == "old" else ["echo 'noop'"],
            },

            # translation push
            {
                "name": "translation-push",
                "image": "owncloudci/transifex:latest",
                "pull": "always",
                "environment": {
                    "TX_TOKEN": from_secret("tx_token"),
                },
                "commands": [
                    "cd '" + path + "'",
                    "make l10n-push",
                ],
            } if mode == "make" else {
                "name": "translation-push-old",
                "image": "owncloudci/transifex:latest",
                "pull": "always",
                "environment": {
                    "TX_TOKEN": from_secret("tx_token"),
                },
                "commands": [
                    "cd '" + path + "/" + sub_path + "'",
                    "tx -d push -s --skip --no-interactive",
                ],
            },

            # translation pull
            {
                "name": "translation-pull",
                "image": "owncloudci/transifex:latest",
                "pull": "always",
                "environment": {
                    "TX_TOKEN": from_secret("tx_token"),
                },
                "commands": [
                    "cd '" + path + "'",
                    "make l10n-pull",
                ],
            } if mode == "make" else {
                "name": "translation-pull-old",
                "image": "owncloudci/transifex:latest",
                "pull": "always",
                "environment": {
                    "TX_TOKEN": from_secret("tx_token"),
                },
                "commands": [
                    "cd '" + path + "/" + sub_path + "'",
                    "tx -d pull -a --skip --minimum-perc=75 -f",
                ],
            },

            # translation writer
            {
                "name": "translation-writer",
                "image": "owncloudci/transifex:latest",
                "pull": "always",
                "environment": {
                    "TX_TOKEN": from_secret("tx_token"),
                },
                "commands": [
                    "cd '" + path + "'",
                    "make l10n-write",
                ],
            } if mode == "make" else {
                "name": "translation-writer-old",
                "image": "owncloudci/transifex:latest",
                "pull": "always",
                "environment": {
                    "TX_TOKEN": from_secret("tx_token"),
                },
                "commands": [
                    "cd '" + path + "/" + sub_path + "'",
                    "l10n '" + name + "' write",
                ] if mode == "old" else ["echo 'noop'"],
            },

            # cleanup
            {
                "name": "translation-cleanup",
                "image": "owncloudci/transifex:latest",
                "pull": "always",
                "environment": {
                    "TX_TOKEN": from_secret("tx_token"),
                },
                "commands": [
                    "cd '" + path + "'",
                    "make l10n-clean",
                ],
            } if mode == "make" else {
                "name": "translation-cleanup-old",
                "image": "owncloudci/transifex:latest",
                "pull": "always",
                "environment": {
                    "TX_TOKEN": from_secret("tx_token"),
                },
                "commands": [
                    "cd '" + path + "/" + sub_path + "'",
                    "find . -name *.po -type f -delete",
                    "find . -name *.pot -type f -delete",
                    "find . -name or_IN.* -type f  -print0 | xargs -r -0 git rm -f",
                    "find . -name uz.* -type f  -print0 | xargs -r -0 git rm -f",
                    "find . -name yo.* -type f  -print0 | xargs -r -0 git rm -f",
                    "find . -name ne.* -type f  -print0 | xargs -r -0 git rm -f",
                ] if mode == "old" else ["echo 'noop'"],
            },

            # translation commit
            {
                "name": "translation-commit",
                "image": "appleboy/drone-git-push:latest",
                "pull": "always",
                "settings": {
                    "ssh_key": from_secret("git_push_ssh_key"),
                    "author_name": "ownClouders",
                    "author_email": "devops@owncloud.com",
                    "remote": git,
                    "remote_name": "upstream",
                    "branch": ref,
                    "empty_commit": False,
                    "commit": True,
                    "commit_message": "[tx] updated from transifex",
                    "no_verify": True,
                    "path": path,
                },
            },
        ],
        "trigger": {
            "event": ["push"],
            "ref": [
                "refs/heads/master",
                "refs/pull/**",
            ],
        },
    }

def notification(depends_on = []):
    return {
        "kind": "pipeline",
        "type": "docker",
        "name": "notification",
        "platform": {
            "os": "linux",
            "arch": "amd64",
        },
        "clone": {
            "disable": True,
        },
        "depends_on": depends_on,
        "steps": [
            {
                "name": "rocketchat",
                "image": "plugins/slack:1",
                "pull": "always",
                "settings": {
                    "webhook": from_secret("slack_webhook"),
                    "channel": "server",
                    "template": "*{{build.status}}* <{{build.link}}|{{repo.owner}}/{{repo.name}}#{{truncate build.commit 8}}>",
                },
            },
        ],
        "trigger": {
            "event": ["push"],
            "status": ["success", "failure"],
        },
    }

def from_secret(name):
    return {
        "from_secret": name,
    }
