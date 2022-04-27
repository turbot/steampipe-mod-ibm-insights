dashboard "ibm_is_security_group_dashboard" {

  title = "IBM Security Group Dashboard"
  documentation = file("./dashboards/network/docs/network_security_group_dashboard.md")

  tags = merge(local.network_common_tags, {
    type = "Dashboard"
  })

  container {

    card {
      sql = query.ibm_is_security_group_count.sql
      width = 2
    }

    card {
      sql = query.ibm_is_security_group_unassociated_count.sql
      width = 2
    }

    card {
      sql = query.ibm_is_security_group_unrestricted_inbound_count.sql
      width = 2
    }


    card {
      sql = query.ibm_is_security_group_unrestricted_outbound_count.sql
      width = 2
    }

  }

  container {

    title = "Assessment"

    chart {
      title = "Association Status"
      type  = "donut"
      width = 3
      sql   = query.ibm_is_security_group_unassociated_status.sql

      series "count" {
        point "associated" {
          color = "ok"
        }
        point "unassociated" {
          color = "alert"
        }
      }
    }

    chart {
      title = "With Unrestricted Inbound (Excludes ICMP)"
      type  = "donut"
      width = 3
      sql   = query.ibm_is_security_group_unrestricted_inbound_status.sql

      series "count" {
        point "restricted" {
          color = "ok"
        }
        point "unrestricted" {
          color = "alert"
        }
      }
    }

    chart {
      title = "With Unrestricted Outbound (Excludes ICMP)"
      type  = "donut"
      width = 3
      sql   = query.ibm_is_security_group_unrestricted_outbound_status.sql

      series "count" {
        point "restricted" {
          color = "ok"
        }
        point "unrestricted" {
          color = "alert"
        }
      }
    }

  }

  container {

    title = "Analysis"

    chart {
      title = "Security Groups by Account"
      sql   = query.ibm_is_security_group_by_acount.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Security Groups by Region"
      sql = query.ibm_is_security_group_by_region.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Security Groups by Resource Group"
      sql = query.ibm_is_security_group_by_resource_group.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Security Groups by Age"
      sql = query.ibm_is_security_group_by_creation_month.sql
      type  = "column"
      width = 4
    }

    chart {
      title = "Security Groups by VPC"
      sql = query.ibm_is_security_group_by_vpc.sql
      type  = "column"
      width = 4
    }

  }

}

# Card Queries

query "ibm_is_security_group_count" {
  sql = <<-EOQ
    select count(*) as "Security Groups" from ibm_is_security_group;
  EOQ
}

query "ibm_is_security_group_unassociated_count" {
  sql = <<-EOQ
    select
      count(*) as value,
      'Unassociated' as label,
      case count(*) when 0 then 'ok' else 'alert' end as type
    from
      ibm_is_security_group
    where
      jsonb_array_length(targets) = 0;
  EOQ
}

query "ibm_is_security_group_unrestricted_inbound_count" {
  sql = <<-EOQ
    with inbound_sg as (
      select
        id,
        count(*)
      from
        ibm_is_security_group,
        jsonb_array_elements(rules) as r
      where
        (r -> 'remote' ->> 'cidr_block' = '0.0.0.0/0')
        and r ->> 'protocol' <> 'icmp'
        and (r ->> 'port_min' = '1' and r ->> 'port_max' = '65535')
        and
          r ->> 'direction' = 'inbound'
        group by
          id
    )
    select
      'Unrestricted Inbound (Excludes ICMP)' as label,
      count(*) as value,
      case
        when count(*) = 0 then 'ok'
        else 'alert'
      end as type
    from
      ibm_is_security_group as sg
      where sg.id in (select id from inbound_sg )
  EOQ
}

query "ibm_is_security_group_unrestricted_outbound_count" {
  sql = <<-EOQ
    with outbound_sg as (
      select
        id,
        count(*)
      from
        ibm_is_security_group,
        jsonb_array_elements(rules) as r
      where
        (r -> 'remote' ->> 'cidr_block' = '0.0.0.0/0')
        and r ->> 'protocol' <> 'icmp'
        and (r ->> 'port_min' = '1' and r ->> 'port_max' = '65535')
        and
          r ->> 'direction' = 'outbound'
        group by
          id
    )
    select
      'Unrestricted Outbound (Excludes ICMP)' as label,
      count(*) as value,
      case
        when count(*) = 0 then 'ok'
        else 'alert'
      end as type
    from
      ibm_is_security_group as sg
      where sg.id in (select id from outbound_sg )
  EOQ
}

# Assessment Queries

query "ibm_is_security_group_unassociated_status" {
  sql = <<-EOQ
    with associated_sg as (
      select
        case when jsonb_array_length(targets) = 0 then 'unassociated' else 'associated' end as association
      from
        ibm_is_security_group
    )
    select
      association,
      count(*)
    from
      associated_sg
    group by
     association;
  EOQ
}

query "ibm_is_security_group_unrestricted_inbound_status" {
  sql = <<-EOQ
    with inbound_sg as (
      select
        id,
        count(*)
      from
        ibm_is_security_group,
        jsonb_array_elements(rules) as r
      where
        (r -> 'remote' ->> 'cidr_block' = '0.0.0.0/0')
        and r ->> 'protocol' <> 'icmp'
        and (r ->> 'port_min' = '1' and r ->> 'port_max' = '65535')
        and
          r ->> 'direction' = 'inbound'
        group by
          id
    )
    select
     case when i.id is null then 'restricted' else 'unrestricted' end as status,
     count(*)
    from
      ibm_is_security_group as sg left join inbound_sg as i on sg.id = i.id
    group by
      status;
  EOQ
}

query "ibm_is_security_group_unrestricted_outbound_status" {
  sql = <<-EOQ
    with outbound_sg as (
      select
        id,
        count(*)
      from
        ibm_is_security_group,
        jsonb_array_elements(rules) as r
      where
        (r -> 'remote' ->> 'cidr_block' = '0.0.0.0/0')
        and r ->> 'protocol' <> 'icmp'
        and (r ->> 'port_min' = '1' and r ->> 'port_max' = '65535')
        and
          r ->> 'direction' = 'outbound'
        group by
          id
    )
    select
      case when o.id is null then 'restricted' else 'unrestricted' end as status,
      count(*)
    from
      ibm_is_security_group as sg left join outbound_sg as o on sg.id = o.id
    group by
      status;
  EOQ
}

# Analysis Queries

query "ibm_is_security_group_by_acount" {
  sql = <<-EOQ
    select
      a.name as "account",
      count(s.*) as "security_groups"
    from
      ibm_is_security_group as s,
      ibm_account as a
    where
      a.customer_id = s.account_id
    group by
      account
    order by
      account;
  EOQ
}

query "ibm_is_security_group_by_region" {
  sql = <<-EOQ
    select
      region as "Region",
      count(*) as "security_groups"
    from
      ibm_is_security_group
    group by
      region
    order by
      region;
  EOQ
}

query "ibm_is_security_group_by_resource_group" {
  sql = <<-EOQ
    select
      resource_group ->> 'name' as "Resource Group",
      count(*) as "security_groups"
    from
      ibm_is_security_group
    group by
      resource_group ->> 'name'
    order by
      resource_group ->> 'name';
  EOQ
}

query "ibm_is_security_group_by_vpc" {
  sql = <<-EOQ
    select
      vpc ->> 'id' as "VPC",
      count(*) as "security_groups"
    from
      ibm_is_security_group
    group by
      vpc ->> 'id'
    order by
       vpc ->> 'id';
  EOQ
}

query "ibm_is_security_group_by_creation_month" {
  sql = <<-EOQ
    with security_group as (
      select
        title,
        created_at,
        to_char(created_at,
          'YYYY-MM') as creation_month
      from
        ibm_is_security_group
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
                from security_group)),
            date_trunc('month',
              current_date),
            interval '1 month') as d
    ),
    security_group_by_month as (
      select
        creation_month,
        count(*)
      from
        security_group
      group by
        creation_month
    )
    select
      months.month,
      security_group_by_month.count
    from
      months
      left join security_group_by_month on months.month = security_group_by_month.creation_month
    order by
      months.month;
  EOQ
}
