dashboard "ibm_compute_instance_dashboard" {

  title         = "IBM Compute Instance Dashboard"
  documentation = file("./dashboards/compute/docs/compute_instance_dashboard.md")

  tags = merge(local.compute_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      sql   = query.ibm_compute_instance_count.sql
      width = 2
    }

    card {
      sql   = query.ibm_compute_instance_total_vcpu.sql
      width = 2
    }

  }

  container {

    title = "Assessments"
    width = 6
  }

  container {

    title = "Analysis"

    chart {
      title = "Instances by Account"
      sql   = query.ibm_compute_instance_by_account.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Region"
      sql   = query.ibm_compute_instance_by_region.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Resource Group"
      sql   = query.ibm_compute_instance_by_resource_group.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Status"
      sql   = query.ibm_compute_instance_by_status.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Age"
      sql   = query.ibm_compute_instance_by_creation_month.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Zone"
      sql   = query.ibm_compute_instance_by_zone.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Architecture"
      sql   = query.ibm_compute_instance_by_architecture.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Instances by Image"
      sql   = query.ibm_compute_instance_by_image.sql
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "ibm_compute_instance_count" {
  sql = <<-EOQ
    select count(*) as "Instances" from ibm_is_instance;
  EOQ
}

query "ibm_compute_instance_total_vcpu" {
  sql = <<-EOQ
    select
      sum((vcpu ->> 'count')::int) as "Total vCPU"
    from
      ibm_is_instance;
  EOQ
}

# Assessment Queries

# Analysis Queries

query "ibm_compute_instance_by_account" {
  sql = <<-EOQ
    select
      a.name as "account",
      count(i.*) as "Total"
    from
      ibm_is_instance as i,
      ibm_account as a
    where
      a.customer_id = i.account_id
    group by
      account
    order by count(i.*) desc
  EOQ
}

query "ibm_compute_instance_by_region" {
  sql = <<-EOQ
    select
      region,
      count(i.*) as total
    from
      ibm_is_instance as i
    group by
      region
  EOQ
}

query "ibm_compute_instance_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group ->> 'name' as "Resource Group",
      count(i.*) as total
    from
      ibm_is_instance as i
    group by
      resource_group ->> 'name';
  EOQ
}

query "ibm_compute_instance_by_status" {
  sql = <<-EOQ
    select
      status,
      count(status)
    from
      ibm_is_instance
    group by
      status;
  EOQ
}

query "ibm_compute_instance_by_creation_month" {
  sql = <<-EOQ
    with instances as (
      select
        title,
        created_at,
        to_char(created_at,
          'YYYY-MM') as creation_month
      from
        ibm_is_instance
    ),
    months as (
      select
        to_char(d,
          'YYYY-MM') as month
      from
        generate_series(date_trunc('month',
            (
              select
                min(created_at)
                from instances)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    instances_by_month as (
      select
        creation_month,
        count(*)
      from
        instances
      group by
        creation_month
    )
    select
      months.month,
      instances_by_month.count
    from
      months
      left join instances_by_month on months.month = instances_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "ibm_compute_instance_by_zone" {
  sql = <<-EOQ
    select
      zone ->> 'name' as "Zone",
      count(i.*) as total
    from
      ibm_is_instance as i
    group by
      zone ->> 'name';
  EOQ
}

query "ibm_compute_instance_by_architecture" {
  sql = <<-EOQ
    select
      vcpu ->> 'architecture' as "Architecture",
      count(i.*) as total
    from
      ibm_is_instance as i
    group by
      vcpu ->> 'architecture';
  EOQ
}

query "ibm_compute_instance_by_image" {
  sql = <<-EOQ
    select
      image ->> 'name' as "Image",
      count(i.*) as total
    from
      ibm_is_instance as i
    group by
      image ->> 'name';
  EOQ
}
