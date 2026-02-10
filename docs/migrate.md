# Migrate Resources

Learn how to migrate your translation resources from one transifex organization or project to another.

This content is derived from [migrate resources](https://community.transifex.com/t/did-you-know-how-to-migrate-resources-from-one-project-to-another/4009#p-7229-using-the-cli-3) and [bulk adding resources](https://developers.transifex.com/docs/cli#adding-remote-resources-in-bulk), and is adapted and tested for this environment. Though step fragments exists when searching the internet, no complete/comprehensive guide exists for this procedure!

Note that `tx push` and `tx delete` commands **require** elevated permissions. See the [project-manager role](ntora-Asciidoc-Extensions/README.md) overview on transifex for more details.

* If you do not have sufficient permissions, you will receive an error message such as:\
`Error while creating resource, 403, permission_denied: You do not have permission to perform this action.`

* Elevated permissions are not required if the resource already exists in the target project.

**Table of Contents**

   * [A Quick Overview of the Steps](#a-quick-overview-of-the-steps)
   * [CLI Installation and API Token](#cli-installation-and-api-token)
      * [Installation](#installation)
      * [API Token](#api-token)
   * [Setup](#setup)
   * [Transifex Hierarchy Info](#transifex-hierarchy-info)
      * [ownCloud Organizations](#owncloud-organizations)
      * [ownCloud Projects](#owncloud-projects)
   * [Create a Configuration](#create-a-configuration)
      * [Prepare the tx Command](#prepare-the-tx-command)
      * [Run the tx Command](#run-the-tx-command)
      * [Remove Irrelevant Configs](#remove-irrelevant-configs)
   * [Download Translations](#download-translations)
   * [Fix Possible Translation String Issues](#fix-possible-translation-string-issues)
   * [Define the Target Project](#define-the-target-project)
   * [Upload to the Target Project](#upload-to-the-target-project)
   * [Review the Pushed Resources](#review-the-pushed-resources)
      * [Delete Faulty Resources](#delete-faulty-resources)
   * [Reconfigure the Source Configuration](#reconfigure-the-source-configuration)
   * [Delete Original Resources](#delete-original-resources)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->

## A Quick Overview of the Steps

* Install and configure the `tx` app
* Create a configuration
* Remove irrelevant resource configs
* Download translations
* Define the target project
* Upload to the target project
* Reconfigure the source configuration
* Delete the resources from the former project location

## CLI Installation and API Token

### Installation

See the [installation](https://developers.transifex.com/docs/cli#installing-with-a-script-linuxmac) documentation to install the `tx` command line client

See the [help documentation](https://developers.transifex.com/docs/using-th-client) for an in depth explanation the `tx` client functionality.

### API Token

In order to use the `tx` app, you must create an API token and provide it, along with other information, in a file. Whenever `tx` is called and accesses transifex, this information is used to authenticate.
 
Visit these links to create your transifex API token: [help](https://help.transifex.com/en/articles/6248858-generating-an-api-token) or directly the [user settings](https://app.transifex.com/user/settings/api/).

**IMPORTANT:** the created token is only shown once!

Create a `~/.transifexrc` file with the following content:
```
[https://app.transifex.com]
rest_hostname = https://rest.api.transifex.com
token         = <token>
```

## Setup

Create a temporary folder to pull/push resources, use a location of chioce such as `transifex` and initialize the transifex setup:

```bash
mkdir transifex
cd transifex
tx init
```

Check that `~/.transifexrc` and `./tx/config` use the same target url:\
`https://app.transifex.com`\
Note that the `tx` commands will not work if the URL is different. The token will be rejected or not used at all.

## Transifex Hierarchy Info

This information will be referenced and/or used in several subsequent configuration steps.

### ownCloud Organizations

There is only one relevant ownCloud `organisation_slug` which is:\
`owncloud-org`

### ownCloud Projects

There are currently the following valid ownCloud projects containing multiple resources:

```
project_slug         printed name
owncloud          -> ownCloud
owncloud-ios      -> ownCloud iOS
owncloud-android  -> ownCloud Android
owncloud-desktop  -> ownCloud Desktop
owncloud-web      -> ownCloud Infinite Scale
```

## Create a Configuration

Create a configuration for the migration automatically based on remote (upstream) data for a specific project. The following description gives an overview and reason of the parameters used.

**Note that the resulting configuration file will define all resources from that project. Then, you must manually delete the irrelevant ones.**

This step will only update the `.tx/config` file, which was initially created by the `tx init` command. However, it will not add any translations.

### Prepare the tx Command

The configuration file is used to modify settings and to retrieve translation data, which are then pushed back to transifex.

The `tx add remote` command used requires a URL at a minimum, but it can also be configured with an option to define a file filter, which is used here.

**Remote URL template:**
* `https://app.transifex.com/<organization_slug>/<project_slug>/dashboard/`

**--file-filter template:**
* Note that the `--file-filter` option does not filter downloadable resources, but rather defines how they will be structured and named on the local disk.

* Replace the `<path-component>` as required to facilitate handling if you want to delete all the pulled translations in one shot.

* The `<project_slug>` is a placeholder for the project name used by `tx`, but it can be replaced by any string.

* The `<resource_slug>`, `<lang>` and `<ext>` are placeholders used by `tx` and need to be present literally.

Final construct of the file-filter option:\
`<path-component>/<project_slug>.<resource_slug>/<lang>.<ext>`

### Run the tx Command

Run the following example command to create a configuration, replacing the `project_slug` (owncloud) as required:

```bash
tx add remote \
    --file-filter 'translations/<project_slug>.<resource_slug>/<lang>.<ext>' \
    'https://app.transifex.com/owncloud-org/owncloud/dashboard/'
```

Note that if you think the local file structure could be improved, you can delete the `.tx` and `translations` directory, run `tx init`, and restart.

### Remove Irrelevant Configs

After successfully running this command, open the `.tx/config` config file with an editor and manually delete all irrelevant resources from the configuration file. Note that all present  resource definitions in the configuration file will be included in upcoming `tx` commands.

## Download Translations

Before downloading the translations defined in the config file, you should consider setting a minimum percentage of translations to be present. With the default setting of `-1` for `--minimum-perc` in the `tx` command, all possible languages will be pulled, regardless of their translation completion rate, which is often unnecessary. You can identify the minimum percentage value by looking into the following example link, replace the placeholders accordingly and filter by `Completion (descending)`:

`https://app.transifex.com/owncloud-org/<project_slug>/<resource_name >/`

Take, for instance, `ownCloud/ocis-xxx` (before the migration), with a value of 4% — a solid figure. Any lower value has no value because of the date of the last changes, which is usually quite distant in the past. Though you define a minimum percentage for regular translation syncs, a language might not make it into the product due to the minimum percentage defined. However, contributors can improve the translation rate, so the work that has already been done is not wasted.

Note that the minimum translation percentage (`minimum-perc`) can be set individually for each resource in the configuration. Setting it as an option in the `tx` command uses it for all resources of the configuration.

To pull all translations of the resources defined in the configuration to the local disk, run the following command:

```bash
tx pull -s -t -all --minimum-perc 4
```

## Fix Possible Translation String Issues

In rare cases, when you upload the data to the final project after pulling, it may happen that the `tx` command complains about unescaped characters. This is a `tx` bug and occurs, as far we have identified, only with strings containing `href="`. In this case, although the source string in the repo has escaped correctly (`href=\"`), `tx` does not pull correctly, it removes escaping, and when pushing, the unescaped character in the string causes issues. Sadly you cant easily just push corrected data after fixing easily, you must delete the upload completely and fix the issue before pushing.

To avoid the issue and have clean sources, run a grep in the transifex folder and check if you are affected:

```bash
grep -rl 'href="'
```

If there are matches, change all unescaped quotes from `"` to `\"` in all files reported.
Note that the affected files may have more unescaped quotes than greped. All unescaped characters of that file need to be escaped manually!
 
## Define the Target Project

This step defines the target project where these resources with their translations will be uploaded to.

Change the project_slug in each resource definition in the config file, for example:

```bash
[o:owncloud-org:p:owncloud:r:ocis-activitylog]
```
will be changed to
```bash
[o:owncloud-org:p:owncloud-web:r:ocis-activitylog]
```

## Upload to the Target Project

Once the targets have been updated in the config file for each resource, push the changes upstream.

**Notes:**

* The `--all` option.\
This option creates empty translation objects for each language in the target project's definition, for which no translation exists locally.

* Contrary, the push argument does not have a "dry run" option. If an error occurs, try adding the `--skip` option.\
An error may occur if languages are present locally which are not defined in the target project and your transifex permissions lack creating them.

```bash
tx push -s -t --all
```

## Review the Pushed Resources

Use a browser to check Transifex and see if the push provided the expected result.

### Delete Faulty Resources

**IMPORTANT:**\
Deleting a resource will remove it from Transifex and from your local config file. Any local translations will remain. Therefore, if you want to re-push, either copy the config file first or open it with an editor before deleting any resources.

If a pushed resource needs to be deleted, run the following command. Use the commands help for details `tx delete --help`:

Example:
```bash
tx delete --force owncloud-web.ocis-userlog
```
Note that the `--force` option is required if this resource has translations on Transifex. You will be notified if it is required but omitted.

The deleted resource is no longer available when reviewing via the browser.

Update the current config file accordingly after fixing the issue with the faulty resource and before trying to re-push.

## Reconfigure the Source Configuration

The `project_slug` must be updated in the **sourcing repository** for all successfully relocated resources. This is done in the same way as described in [Define the Target Project](#define-the-target-project).

Create a PR for this change and merge it.

## Delete Original Resources

After merging the PR and running the `translation-sync` successfully (either manually or via the nightly job), if no issues arise, you can safely delete the resources from the original project. You can do this via the Transifex GUI or the command line.

* From the GUI, as an example, select the [owncloud](https://app.transifex.com/owncloud-org/owncloud/content/) project and filter the resource to be deleted, such as `ocis-`. Then checkmark all mathcing resources and press delete.

* From the command line, you need to re-set the `project_slug` in the config to its original location (such as `owncloud`) and the remove the resource as described in [Delete Faulty Resources](#delete-faulty-resources).

