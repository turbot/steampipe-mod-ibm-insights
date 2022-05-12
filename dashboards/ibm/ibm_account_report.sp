dashboard "ibm_account_report" {

  title         = "IBM Account Report"
  documentation = file("./dashboards/ibm/docs/ibm_account_report.md")

  tags = merge(local.ibm_common_tags, {
    type     = "Report"
    category = "Accounts"
  })

  container {

    card {
      sql   = query.ibm_account_count.sql
      width = 2
    }

  }

  table {

    sql = query.ibm_account_table.sql
  }

}

query "ibm_account_count" {
  sql = <<-EOQ
    select
      count(*) as "Accounts"
    from
      ibm_account;
  EOQ
}

query "ibm_account_table" {
  sql = <<-EOQ
    select
      a.name as "Name",
      a.customer_id as "Customer ID",
      a.owner_user_id as "Owner User ID",
      a.owner_unique_id as "Owner Unique ID",
      a.organizations as "Organizations",
      s.mfa as "MFA",
      a.state as "State",
      a.type as "Type"
    from
      ibm_account as a left join ibm_iam_account_settings s on a.customer_id = s.account_id
    order by
      a.name;
  EOQ
}
