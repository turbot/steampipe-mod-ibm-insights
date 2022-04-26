dashboard "ibm_cos_bucket_lifecycle_report" {

  title         = "IBM COS Bucket Lifecycle Report"
  documentation = file("./dashboards/cos/docs/cos_bucket_report_lifecycle.md")

  tags = merge(local.cos_common_tags, {
    type     = "Report"
    category = "Lifecycle"
  })

  container {

    card {
      sql   = query.ibm_cos_bucket_count.sql
      width = 2
    }

    card {
      sql   = query.ibm_cos_bucket_versioning_disabled_count.sql
      width = 2
    }

    card {
      sql   = query.ibm_cos_bucket_versioning_mfa_disabled_count.sql
      width = 2
    }

  }

  table {

    sql = query.ibm_cos_bucket_lifecycle_table.sql
  }

}

query "ibm_cos_bucket_lifecycle_table" {
  sql = <<-EOQ
    select
      b.name as "Name",
      case when b.versioning_enabled then 'Enabled' else null end as "Versioning",
      case when b.versioning_mfa_delete then 'Enabled' else null end as "Versioning MFA Delete",
      b.region as "Region"
    from
      ibm_cos_bucket as b
    order by
      b.name;
  EOQ
}
