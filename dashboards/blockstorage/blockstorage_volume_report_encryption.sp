dashboard "ibm_is_volume_encryption_report" {

  title         = "IBM Block Storage Volume Encryption Report"
  documentation = file("./dashboards/blockstorage/docs/blockstorage_volume_report_encryption.md")

  tags = merge(local.blockstorage_common_tags, {
    type     = "Report"
    category = "Encryption"
  })

  container {

    card {
      query = query.ibm_is_volume_count
      width = 2
    }

    card {
      query = query.ibm_is_volume_provider_managed_encryption_count
      width = 2
    }

    card {
      query = query.ibm_is_volume_user_managed_encryption_count
      width = 2
    }

  }

  table {

    column "Account ID" {
      display = "none"
    }

    column "CRN" {
      display = "none"
    }

    column "ID" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.ibm_is_volume_detail.url_path}?input.volume_crn={{.CRN | @uri}}"
    }

    query = query.ibm_is_volume_encryption_report
  }

}

query "ibm_is_volume_encryption_report" {
  sql = <<-EOQ
    select
      v.name as "Name",
      v.encryption as "Encryption Type",
      v.encryption_key as "Encryption Key",
      a.name as "Account",
      v.account_id as "Account ID",
      v.region as "Region",
      v.zone ->> 'name' as "Zone",
      v.resource_group ->> 'name' as "Resource Group",
      v.crn as "CRN",
      v.id as "ID"
    from
      ibm_is_volume as v,
      ibm_account as a
    where
      v.account_id = a.customer_id
    order by
      v.name;
  EOQ
}

query "ibm_is_volume_provider_managed_encryption_count" {
  sql = <<-EOQ
    select
      count(*) as "Provider-Managed Encryption"
    from
      ibm_is_volume
    where
      encryption = 'provider_managed';
  EOQ
}

query "ibm_is_volume_user_managed_encryption_count" {
  sql = <<-EOQ
   select
      count(*) as "User-Managed Encryption"
    from
      ibm_is_volume
    where
      encryption = 'user_managed';
  EOQ
}
