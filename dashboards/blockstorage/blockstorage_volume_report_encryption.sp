dashboard "blockstorage_volume_report_encryption" {

  title         = "IBM Block Storage Volume Encryption Report"
  documentation = file("./dashboards/blockstorage/docs/blockstorage_volume_report_encryption.md")

  tags = merge(local.blockstorage_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.blockstorage_volume_count
      width = 3
    }

    card {
      query = query.blockstorage_volume_provider_managed_encryption_count
      width = 3
    }

    card {
      query = query.blockstorage_volume_user_managed_encryption_count
      width = 3
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    column "CRN" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.blockstorage_volume_detail.url_path}?input.volume_crn={{.CRN | @uri}}"
    }

    query = query.blockstorage_volume_encryption_report
  }

}

query "blockstorage_volume_encryption_report" {
  sql = <<-EOQ
    select
      v.name as "Name",
      v.id as "ID",
      v.encryption as "Encryption Type",
      v.encryption_key as "Encryption Key",
      a.name as "Account",
      v.account_id as "Account ID",
      v.region as "Region",
      v.zone ->> 'name' as "Zone",
      v.resource_group ->> 'name' as "Resource Group",
      v.crn as "CRN"
    from
      ibm_is_volume as v,
      ibm_account as a
    where
      v.account_id = a.customer_id
    order by
      v.name;
  EOQ
}

query "blockstorage_volume_provider_managed_encryption_count" {
  sql = <<-EOQ
    select
      count(*) as "Provider-Managed Encryption"
    from
      ibm_is_volume
    where
      encryption = 'provider_managed';
  EOQ
}

query "blockstorage_volume_user_managed_encryption_count" {
  sql = <<-EOQ
   select
      count(*) as "User-Managed Encryption"
    from
      ibm_is_volume
    where
      encryption = 'user_managed';
  EOQ
}
