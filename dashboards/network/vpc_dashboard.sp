dashboard "ibm_is_vpc_dashboard" {

  title = "IBM VPC Dashboard"
  documentation = file("./dashboards/network/docs/vpc_dashboard.md")

  tags = merge(local.network_common_tags, {
    type = "Dashboard"
  })

  container {

    # Analysis
    card {
      sql   = query.ibm_is_vpc_count.sql
      width = 2
    }

    card {
      sql = query.ibm_classic_infrastructure_vpc_count.sql
      width = 2
    }

    # Assessments
    card {
      sql = query.ibm_is_vpc_no_subnet_count.sql
      width = 2
    }

  }

  container {

    title = "Assessments"

    chart {
      title = "Empty VPCs (No Subnets)"
      type  = "donut"
      width = 3
      sql   = query.ibm_is_vpc_empty_status.sql

      series "count" {
        point "non-empty" {
          color = "ok"
        }
        point "empty" {
          color = "alert"
        }
      }
    }
  }

  container {

    title = "Analysis"

    chart {
      title = "VPCs by Account"
      sql   = query.ibm_is_vpc_by_account.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "VPCs by Resource Group"
      sql   = query.ibm_is_vpc_by_resource_group.sql
      type  = "column"
      legend {
        position = "bottom"
      }
      width = 4
    }

    chart {
      title = "VPCs by Region"
      sql   = query.ibm_is_vpc_by_region.sql
      type  = "column"
      legend {
        position = "bottom"
      }
      width = 4
    }

    chart {
      title = "VPCs by Age"
      sql   = query.ibm_is_vpc_by_creation_month.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "VPCs by Size"
      sql   = query.ibm_is_vpc_by_size.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "VPCs by RFC1918 Range"
      sql   = query.ibm_is_vpc_by_rfc1918_range.sql
      type  = "column"
      width = 4
    }
  }

}

# Card Queries

query "ibm_is_vpc_count" {
  sql = <<-EOQ
    select count(*) as "VPCs" from ibm_is_vpc;
  EOQ
}

query "ibm_classic_infrastructure_vpc_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'VPCs With Classic Access' as label
    from
      ibm_is_vpc
    where
      classic_access;
  EOQ
}

query "ibm_is_vpc_no_subnet_count" {
  sql = <<-EOQ
    select
       count(*) as value,
      'VPCs Without Subnets' as label,
       case when count(*) = 0 then 'ok' else 'alert' end as type
    from
      ibm_is_vpc as v
      left join ibm_is_subnet as s on v.id = s.vpc ->> 'id'
    where
      s.id is null
  EOQ
}

# Assessment Queries

query "ibm_is_vpc_empty_status" {
  sql = <<-EOQ
    with by_empty as (
      select
        vpc.id,
        case when s.id is null then 'empty' else 'non-empty' end as status
      from
        ibm_is_vpc as vpc
        left join ibm_is_subnet as s on vpc.id = s.vpc ->> 'id'
    )
    select
      status,
      count(*)
    from
      by_empty
    group by
      status;
  EOQ
}

# Analysis Queries

query "ibm_is_vpc_by_account" {
  sql = <<-EOQ
    select
      a.name as "account",
      count(v.*) as "VPCs"
    from
      ibm_is_vpc as v,
      ibm_account as a
    where
      v.account_id = a.customer_id
    group by
      account
    order by
      account;
  EOQ
}

query "ibm_is_vpc_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "VPCs"
    from
      ibm_is_vpc
    group by
      region
    order by
      region;
  EOQ
}

query "ibm_is_vpc_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group ->> 'name' as "Resource Group",
      count(*) as "VPCs"
    from
      ibm_is_vpc
    group by
      resource_group ->> 'name'
    order by
      resource_group ->> 'name';
  EOQ
}

query "ibm_is_vpc_by_creation_month" {
  sql = <<-EOQ
    with vpcs as (
      select
        title,
        created_at,
        to_char(created_at,
          'YYYY-MM') as creation_month
      from
        ibm_is_vpc
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
                from vpcs)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    vpcs_by_month as (
      select
        creation_month,
        count(*)
      from
        vpcs
      group by
        creation_month
    )
    select
      months.month,
      vpcs_by_month.count
    from
      months
      left join vpcs_by_month on months.month = vpcs_by_month.creation_month
    order by
      months.month;
  EOQ
}

query "ibm_is_vpc_by_size" {
  sql = <<-EOQ
    with vpc_size as (
      select
        id,
        a -> 'cidr' as cidr_block,
        concat(
          '/', masklen((a ->> 'cidr')::cidr),
          ' (', power(2, 32 - masklen((a ->> 'cidr')::cidr)), ')'
        ) as size
      from
        ibm_is_vpc,
        jsonb_array_elements(address_prefixes) as a
    )
    select
      size,
      count(*)
    from
      vpc_size
    group by
      size;
  EOQ
}

query "ibm_is_vpc_by_rfc1918_range" {
  sql = <<-EOQ
    with cidr_buckets as (
      select
        id,
        title,
        a ->> 'cidr' as cidr,
        case
          when (a ->> 'cidr')::cidr <<= '10.0.0.0/8'::cidr then '10.0.0.0/8'
          when (a ->> 'cidr')::cidr <<= '172.16.0.0/12'::cidr then '172.16.0.0/12'
          when (a ->> 'cidr')::cidr <<= '192.168.0.0/16'::cidr then '192.168.0.0/16'
          else 'Public Range'
        end as rfc1918_bucket
      from
        ibm_is_vpc,
        jsonb_array_elements(address_prefixes) as a
    )
    select
      rfc1918_bucket,
      count(*)
    from
      cidr_buckets
    group by
      rfc1918_bucket
    order by
      rfc1918_bucket
  EOQ
}