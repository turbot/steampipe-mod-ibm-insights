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
      name as "Name",
      customer_id as "Customer ID",
      owner_user_id as "Owner User ID",
      owner_unique_id as "Owner Unique ID",
      organizations as "Organizations",
      state as "State",
      type as "Type"
    from
      ibm_account
    order by
      name;
  EOQ
}
