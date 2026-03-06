# Finding and Fixing Sync Issues

**Table of Contents**

   * [Background Info](#background-info)
   * [Identification](#identification)
   * [Fixing](#fixing)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->

## Background Info

The way drone is currently setup syncing translations has a downside. If there is an issue with one translation string, in particular e.g. unescaped forbidden characters, the respective drone step passes but no sync is taking place. This means, from the outside everything is ok, but newly created strings from that repo are not pushed to Transifex! Note that pulling, getting back translations to the repo, is not affected.

**IMPORTANT:**

* `tx push -s` only pushes if no failure is identified.\
Using the `--silent` option let `tx` exit on the first issue found without error (exit 0) and other steps will continue to run. Therefore, **a green CI does not tell everything went well...**

## Identification

From the repo in question, look into the resperctive translation-sync step `translation-push` or `translation-push-old` and search for the following console example output:\
`owncloud-android.android - failed to upload of resource 'o:owncloud-org:p:ownc...`\
The text was literaly copied from drone console...! Note that due to a bug in `tx`, the output is cut exactly as in the example and one cant see what the cause is.

## Fixing

If not already done, prepare your Trasnifex [API Token](./migrate.md#api-token) for local use.

All translation push steps use the following command: `tx push -s --silent`. Change into the repo in question to the location where the `.tx/config` file resides. Note that the console log e.g. `owncloud-android.android` guides you, at least a bit: the part before the dot tells that it is likely the Android repo while the part after the dot is the resource you are looking for. Note that this is only a guideline and things may differ... Also note that a repo can have more than one config, one for each sub structure such as you have in ocis where only some services have translatable strings.


**IMPORTANT:**

* Due to a bug in the `tx` CLI tool, you need to extend the width of the shell significantly beforehand to ensure that the entire log is printed. Otherwise, only a fraction of the log will be printed. (An issue has been logged with Transifex to resolve this.)

At the location of the Transifex config file, run the following command from a shell.

```bash
tx push -s --silent
```

This should print out the root cause such as:\
`owncloud-android.android - failed to upload of resource 'o:owncloud-org:p:owncloud-android:r:android' - parse_error: 
: ', ", @, ?, \n, \t in the string: '"I want to invite you to use %1$s on your smartphone!\\nDownload here: %2$s"'`

Here you can identify the culprit. The text in question is embedded in single quotes and everything inbetween needs to be checked. In this example, we have unescaped double quotes at the beginning and the end which either need to be removed or escaped.

After fixing, re-run the tx push command to see if the issue has been fixed or more fixes need to be applied, maybe on other source strings!

If all fixes have been applied and the tx push command passes succesfully, create a PR from the changes made and get it approved and merged. Note that tx push already pushed all missing strings to transifex. After merging and the regular nightly sync has run (or a triggered manual sync), check the drone/translation-sync to see if the failure described above is gone.
