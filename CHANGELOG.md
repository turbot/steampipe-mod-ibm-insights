## v0.5 [2024-03-06]

_Powerpipe_

[Powerpipe](https://powerpipe.io) is now the preferred way to run this mod!  [Migrating from Steampipe →](https://powerpipe.io/blog/migrating-from-steampipe)

All v0.x versions of this mod will work in both Steampipe and Powerpipe, but v1.0.0 onwards will be in Powerpipe format only.

_Enhancements_

- Focus documentation on Powerpipe commands.
- Show how to combine Powerpipe mods with Steampipe plugins.

## v0.4 [2023-11-03]

_Breaking changes_

- Updated the plugin dependency section of the mod to use `min_version` instead of `version`. ([#41](https://github.com/turbot/steampipe-mod-ibm-insights/pull/41))

_Bug fixes_

- Fixed dashboard localhost URLs in README and index doc. ([#37](https://github.com/turbot/steampipe-mod-ibm-insights/pull/37))

## v0.3 [2022-10-14]

_Bug fixes_

- Fixed `ibm_compute_instance_age_table` query in Compute Instance Age Report dashboard. ([#31](https://github.com/turbot/steampipe-mod-ibm-insights/pull/31))

## v0.2 [2022-05-17]

_Bug fixes_

- Updated "IBM Cloud" plugin references in index doc and README.

_Dependencies_

- IBM Cloud plugin `v0.1.0` or higher is now required.

## v0.1 [2022-05-12]

_What's new?_

New dashboards, reports, and details for the following services:
- Block Storage
- Compute
- KMS
- VPC
