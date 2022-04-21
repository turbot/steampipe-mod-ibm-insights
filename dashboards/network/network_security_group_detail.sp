dashboard "ibm_is_security_group_detail" {

  title = "IBM Security Group Detail"
  documentation = file("./dashboards/network/docs/network_security_group_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "security_group_crn" {
    title = "Select a security group:"
    sql   = query.ibm_is_security_group_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.ibm_is_security_group_inbound_rules_count
      args  = {
        crn = self.input.security_group_crn.value
      }
    }

    card {
      width = 2
      query = query.ibm_is_security_group_outbound_rules_count
      args  = {
        crn = self.input.security_group_crn.value
      }
    }

    card {
      width = 2
      query = query.ibm_is_security_group_attached_enis_count
      args  = {
        crn = self.input.security_group_crn.value
      }
    }

    card {
      width = 2
      query = query.ibm_is_security_group_unrestricted_inbound
      args  = {
        crn = self.input.security_group_crn.value
      }
    }

    card {
      width = 2
      query = query.ibm_is_security_group_unrestricted_outbound
      args  = {
        crn = self.input.security_group_crn.value
      }
    }

  }

  container {

    container {
      width = 6

      table {
        title = "Overview"
        type  = "line"
        width = 6
        query = query.ibm_is_security_group_overview
        args  = {
          crn = self.input.security_group_crn.value
        }

      }

      table {
        title = "Tags"
        width = 6
        query = query.ibm_is_security_group_tags
        args  = {
          crn = self.input.security_group_crn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Associated to"
        query = query.ibm_is_security_group_association
        args  = {
          crn = self.input.security_group_crn.value
        }


      }

    }

  }

  container {

    width = 6

    table {
      title = "Inbound Rules"
      query = query.ibm_is_security_group_inbound_rules
      args  = {
        crn = self.input.security_group_crn.value
      }
    }

  }

  container {

    width = 6

    table {
      title = "Outbound Rules"
      query = query.ibm_is_security_group_outbound_rules
      args = {
        crn = self.input.security_group_crn.value
      }
    }

  }

}

query "ibm_is_security_group_input" {
  sql = <<-EOQ
    select
      title as label,
      crn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'id', id
      ) as tags
    from
      ibm_is_security_group
    order by
      title;
  EOQ
}

query "ibm_is_security_group_inbound_rules_count" {
  sql = <<-EOQ
    select
      'Inbound Rules' as label,
      count(*) as value
    from
      ibm_is_security_group,
      jsonb_array_elements(rules) as r
    where
      r ->> 'direction' = 'inbound'
      and crn = $1
  EOQ

  param "crn" {}
}

query "ibm_is_security_group_outbound_rules_count" {
  sql = <<-EOQ
    select
      'Outbound Rules' as label,
      count(*) as value
    from
      ibm_is_security_group,
      jsonb_array_elements(rules) as r
    where
      r ->> 'direction' = 'outbound'
      and crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_is_security_group_attached_enis_count" {
  sql = <<-EOQ
    select
      'Attached ENIs' as label,
      jsonb_array_length(network_interfaces) as value,
      case when jsonb_array_length(network_interfaces) > '0' then 'ok' else 'alert' end as type
    from
      ibm_is_security_group
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_is_security_group_unrestricted_inbound" {
  sql = <<-EOQ
    select
      'Unrestricted Inbound (Excludes ICMP)' as label,
      count(*) as value,
      case
        when count(*) = 0 then 'ok'
        else 'alert'
      end as type
    from
      ibm_is_security_group,
      jsonb_array_elements(rules) as r
    where
      (r -> 'remote' ->> 'cidr_block' = '0.0.0.0/0')
      and r ->> 'protocol' <> 'icmp'
      and ( r ->> 'port_min' = '1' and r ->> 'port_max' = '65535')
      and r ->> 'direction' = 'inbound'
      and crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_is_security_group_unrestricted_outbound" {
  sql = <<-EOQ
    select
      'Unrestricted Outbound (Excludes ICMP)' as label,
      count(*) as value,
      case
        when count(*) = 0 then 'ok'
        else 'alert'
      end as type
    from
      ibm_is_security_group,
      jsonb_array_elements(rules) as r
    where
      (  r -> 'remote' ->> 'cidr_block' = '0.0.0.0/0')
      and r ->> 'protocol' <> 'icmp'
      and ( r ->> 'port_min' = '1' and r ->> 'port_max' = '65535')
      and r ->> 'direction' = 'outbound'
      and crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_is_security_group_inbound_rules" {
  sql = <<-EOQ
    select
      concat(text(r -> 'remote' ->> 'cidr_block'), (r -> 'remote' ->> 'id'),(r -> 'remote' ->> 'address')) as "Source",
      r ->> 'id' as "Security Group Rule ID",
      case
        when r ->> 'protocol' = 'all' then 'All Traffic'
        else r ->> 'protocol'
      end as "Protocol",
      case
        when r ->> 'port_min' is null and r ->> 'port_max' is null then null
        when r ->> 'port_min' is not null
          and r ->> 'port_max' is not null
          and (r ->> 'port_min') = (r ->> 'port_max') then (r ->> 'port_min')::text
        else concat(
          (r ->> 'port_min'),
          '-',
          (r ->> 'port_max')
        )
      end as "Ports"
    from
      ibm_is_security_group,
      jsonb_array_elements(rules) as r
    where
      crn = $1
      and r ->> 'direction' = 'inbound';
  EOQ

  param "crn" {}
}

query "ibm_is_security_group_outbound_rules" {
  sql = <<-EOQ
    select
      concat(text(r -> 'remote' ->> 'cidr_block'), (r -> 'remote' ->> 'id'),(r -> 'remote' ->> 'address')) as "Source",
      r ->> 'id' as "Security Group Rule ID",
      case
        when r ->> 'protocol' = 'all' then 'All Traffic'
        else r ->> 'protocol'
      end as "Protocol",
      case
        when r ->> 'port_min' is null and r ->> 'port_max' is null then null
        when r ->> 'port_min' is not null
          and r ->> 'port_max' is not null
          and (r ->> 'port_min') = (r ->> 'port_max') then (r ->> 'port_min')::text
        else concat(
          (r ->> 'port_min'),
          '-',
          (r ->> 'port_max')
        )
      end as "Ports"
    from
      ibm_is_security_group,
      jsonb_array_elements(rules) as r
    where
      crn = $1
      and r ->> 'direction' = 'outbound'
  EOQ

  param "crn" {}
}

query "ibm_is_security_group_overview" {
  sql   = <<-EOQ
    select
      name as "Name",
      id as "ID",
      vpc ->> 'id' as  "VPC ID",
      resource_group ->> 'name' as "Resource Group",
      region as "Region",
      account_id as "Account ID",
      href as "HREF",
      crn as "CRN"
    from
      ibm_is_security_group
    where
      crn = $1
    EOQ

  param "crn" {}
}


query "ibm_is_security_group_association" {
  sql = <<-EOQ
    select
      t ->> 'name' as "Name",
      t ->> 'id' as "ID",
      t ->> 'resource_type' as "Resource Type",
      t ->> 'href' as "HREF"
    from
      ibm_is_security_group,
      jsonb_array_elements(targets) as t
    where
      crn = $1;
  EOQ

  param "crn" {}
}

query "ibm_is_security_group_tags" {
  sql = <<-EOQ
    select
       (trim('"' FROM tag::text)) as "User Tag"
    from
      ibm_is_security_group,
      jsonb_array_elements(tags) as tag
    where
      crn = $1
    order by
      tag;
    EOQ

  param "crn" {}
}
