dashboard "ibm_vpc_detail" {

  title = "IBM VPC Detail"
  documentation = file("./dashboards/network/docs/vpc_detail.md")

  tags = merge(local.network_common_tags, {
    type = "Detail"
  })

  input "vpc_crn" {
    title = "Select a VPC:"
    sql   = query.ibm_is_vpc_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.ibm_is_vpc_num_ips_for_vpc
      args  = {
        crn = self.input.vpc_crn.value
      }
    }

    card {
      width = 2
      query = query.ibm_subnet_count_for_vpc
      args  = {
        crn = self.input.vpc_crn.value
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
        query = query.ibm_is_vpc_overview
        args  = {
          crn = self.input.vpc_crn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.ibm_is_vpc_tags
        args  = {
          crn = self.input.vpc_crn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Address Prefixes"
        query = query.ibm_is_vpc_address_prefixes
        args  = {
          crn = self.input.vpc_crn.value
        }
      }

    }

  }

  container {

    title = "Subnets"

    chart {
      title = "Subnets by Zone"
      type  = "column"
      width = 4
      query = query.ibm_is_vpc_subnet_by_zone
      args = {
        crn = self.input.vpc_crn.value
      }
    }

    table {
      query = query.ibm_is_vpc_subnets_for_vpc
      width = 8
      args = {
        crn = self.input.vpc_crn.value
      }
    }

  }

  container {

    title = "Network ACLs"

    flow {
      base  = flow.nacl_flow
      title = "Network ACLs Inbound Analysis"
      width = 6
      query = query.ibm_inbound_nacl_for_vpc_sankey
      args = {
        crn = self.input.vpc_crn.value
      }
    }


    flow {
      base  = flow.nacl_flow
      title = "Network ACLs Outbound Analysis"
      width = 6
      query = query.ibm_outbound_nacl_for_vpc_sankey
      args = {
        crn = self.input.vpc_crn.value
      }
    }

  }

  table {
    title = "Network ACLs"
    query = query.ibm_is_vpc_network_acl
    args = {
      crn = self.input.vpc_crn.value
    }
  }


  table {
    title = "Cloud Service Endpoint Source Addresses"
    query = query.ibm_is_vpc_cse_source_ip_addresses
    args = {
      crn = self.input.vpc_crn.value
    }
  }


  table {
    title = "Security Groups"
    query = query.ibm_is_vpc_security_groups
    args = {
      crn = self.input.vpc_crn.value
    }

    column "CRN" {
      display = "none"
    }

    column "Name" {
      href = "${dashboard.ibm_security_group_detail.url_path}?input.security_group_crn={{.CRN | @uri}}"
    }
  }
}

flow "nacl_flow" {
  width = 6
  type  = "sankey"


  category "drop" {
    color = "alert"
  }

  category "accept" {
    color = "ok"
  }

}

query "ibm_is_vpc_input" {
  sql = <<-EOQ
    select
      title as label,
      crn as value,
      json_build_object(
        'account_id', account_id,
        'region', region,
        'crn', crn
      ) as tags
    from
      ibm_is_vpc
    order by
      title;
  EOQ
}

query "ibm_subnet_count_for_vpc" {
  sql = <<-EOQ
    select
      'Subnets' as label,
      count(*) as value,
      case when count(*) > 0 then 'ok' else 'alert' end as type
    from
      ibm_is_subnet as s
      left join  ibm_is_vpc as v on v.id = s.vpc ->> 'id'
    where
      v.crn = $1
  EOQ

  param "crn" {}
}

query "ibm_is_vpc_num_ips_for_vpc" {
  sql = <<-EOQ
    with cidrs as (
      select
        a ->> 'cidr' as cidr_block,
        masklen(( a ->> 'cidr')::cidr)  as "Mask Length",
        power(2, 32 - masklen( (a ->> 'cidr'):: cidr)) as num_ips
      from
        ibm_is_vpc,
        jsonb_array_elements(address_prefixes) as a
      where crn = $1
    )
    select
      sum(num_ips) as "IP Addresses"
    from
      cidrs
  EOQ

  param "crn" {}
}

query "ibm_is_vpc_subnets_for_vpc" {
  sql = <<-EOQ
    with subnets as (
      select
        id,
        name,
        tags,
        ipv4_cidr_block,
        zone ->> 'name' as zone,
        available_ipv4_address_count,
        power(2, 32 - masklen(ipv4_cidr_block :: cidr)) -1 as raw_size
      from
        ibm_is_subnet
      where
        vpc ->> 'crn' = $1
    )
    select
      id as "Subnet ID",
      name as "Name",
      ipv4_cidr_block as "CIDR Block",
      zone as " Zone",
      available_ipv4_address_count as "Available IPs",
      power(2, 32 - masklen(ipv4_cidr_block :: cidr)) -1 as "Total IPs",
      round(100 * (available_ipv4_address_count / (raw_size))::numeric, 2) as "% Free"
    from
      subnets
    order by
      id;
  EOQ

  param "crn" {}
}

query "ibm_is_vpc_security_groups" {
  sql = <<-EOQ
    select
      name as "Name",
      id as "ID",
      href as "HREF",
      crn as "CRN"
    from
      ibm_is_security_group
    where
      vpc ->> 'crn' = $1
  EOQ

  param "crn" {}
}

query "ibm_is_vpc_network_acl" {
  sql = <<-EOQ
    select
      name  as "Name",
      id as "ID",
      href as "HREF"
    from
      ibm_is_network_acl
    where
      vpc ->> 'crn' = $1
    order by
      name;
  EOQ

  param "crn" {}
}

query "ibm_is_vpc_overview" {
  sql = <<-EOQ
    select
      name as "Name",
      id as "ID",
      status as "Status",
      title as "Title",
      href as "HREF",
      resource_group ->> 'name' as "Resource Group",
      region as "Region",
      account_id as "Account ID",
      crn as "CRN"
    from
      ibm_is_vpc
    where
      crn = $1
  EOQ

  param "crn" {}
}

query "ibm_is_vpc_address_prefixes" {
  sql = <<-EOQ
    select
      (trim('"' FROM (p ->> 'cidr')))::cidr as "Address Prefix",
      power(2, 32 - masklen( (trim('"' FROM (p ->> 'cidr')) ):: cidr)) as "Total IPs"
    from
      ibm_is_vpc,
      jsonb_array_elements(address_prefixes) as p
    where
      crn = $1
  EOQ

  param "crn" {}
}

query "ibm_is_vpc_subnet_by_zone" {
  sql   = <<-EOQ
    select
      zone ->> 'name' as Zone,
      count(*)
    from
      ibm_is_subnet
    where
      vpc ->> 'crn' = $1
    group by
      zone ->> 'name'
    order by
      zone ->> 'name';
  EOQ

  param "crn" {}
}

query "ibm_is_vpc_cse_source_ip_addresses" {
  sql = <<-EOQ
    select
      i -> 'ip' ->> 'address' as "IP Address",
      i -> 'zone' ->> 'name' as "Zone Name",
      i -> 'zone' ->> 'href' as "HREF"
    from
      ibm_is_vpc,
      jsonb_array_elements(cse_source_ips) as i
    where
      crn = $1
  EOQ

  param "crn" {}
}

query "ibm_inbound_nacl_for_vpc_sankey" {
  sql = <<-EOQ

    with aces as (
      select
        crn,
        title,
        id as network_acl_id,
        e ->> 'protocol' as protocol,
        e ->> 'source' as cidr_block,
        e ->> 'action' as rule_action,
        e -> 'name' as rule_name,

        case when e ->> 'action' = 'allow' then 'Allow ' else 'Deny ' end ||
          case
            when e ->>'protocol' = 'all' then 'All Traffic'
            when e ->>'protocol' = 'icmp' then 'All ICMP'
            when e ->>'protocol' = 'udp' and e ->> 'source_port_min' = '1' and e ->> 'source_port_max' = '65535'
              then 'All UDP'
            when e ->>'protocol' = 'tcp' and e ->>'source_port_min' = '1' and e ->>'source_port_max' = '65535'
              then  'All TCP'
            when e ->>'protocol' = 'tcp' and e ->> 'source_port_min' = e ->> 'source_port_max'
              then  concat(e ->> 'source_port_min', '/TCP')
            when e->>'protocol' = 'udp' and e ->> 'source_port_min'  = e ->> 'source_port_max'
              then  concat(e->> 'source_port_min', '/UDP')
            when e->>'protocol' = 'tcp' and e ->> 'source_port_min' <> e->> 'source_port_max'
              then  concat(e ->> 'source_port_min', '-', e ->> 'source_port_max', '/TCP')
            when e->>'protocol' = 'udp' and e ->> 'source_port_min' <> e->> 'source_port_max'
              then  concat(e ->> 'source_port_min', '-', e ->> 'source_port_max', '/udp')
            else concat('Procotol: ', e->>'protocol')
        end as rule_description,
        a ->> 'id' as subnet_id
      from
        ibm_is_network_acl,
        jsonb_array_elements(rules) as e,
        jsonb_array_elements(subnets) as a
      where
        vpc ->> 'crn' = $1
        and e ->> 'direction' = 'inbound'

    )
    -- CIDR Nodes
    select
      distinct cidr_block as id,
      cidr_block as title,
      'cidr_block' as category,
      null as from_id,
      null as to_id
    from aces

    -- Rule Nodes
    union select
      concat(network_acl_id, '_', rule_name) as id,
      rule_description as title,
      'rule' as category,
      null as from_id,
      null as to_id
    from aces

    -- ACL Nodes
    union select
      distinct s.network_acl_id as id,
      acl.name as title,
      'nacl' as category,
      null as from_id,
      null as to_id
    from aces as s left join ibm_is_network_acl as acl on s.network_acl_id = acl.id

    -- Subnet node
    union select
      distinct a.subnet_id as id,
      s.name as title,
      'subnet' as category,
      null as from_id,
      null as to_id
    from aces as a left join ibm_is_subnet as s on s.id = a.subnet_id

    -- ip -> rule edge
    union select
      null as id,
      null as title,
      rule_action as category,
      cidr_block as from_id,
      concat(network_acl_id, '_', rule_name) as to_id
    from aces

    -- rule -> NACL edge
    union select
      null as id,
      null as title,
      rule_action as category,
      concat(network_acl_id, '_', rule_name) as from_id,
      network_acl_id as to_id
    from aces

    -- nacl -> subnet edge
    union select
      null as id,
      null as title,
      'attached' as category,
      network_acl_id as from_id,
      subnet_id as to_id
    from aces

  EOQ

  param "crn" {}
}

query "ibm_outbound_nacl_for_vpc_sankey" {
  sql = <<-EOQ

    with aces as (
      select
        crn,
        title,
        id as network_acl_id,
        e -> 'Protocol' as protocol,
        e ->> 'source' as cidr_block,
        e ->> 'action' as rule_action,
        e -> 'name' as rule_name,
       case
              when e ->>'protocol' = 'all' then 'All Traffic'
              when e ->>'protocol' = 'icmp' then 'All ICMP'
              when e ->>'protocol' = 'udp' and e ->> 'source_port_min' = '1' and e ->> 'source_port_max' = '65535'
                then 'All UDP'
              when e ->>'protocol' = 'tcp' and e ->>'source_port_min' = '1' and e ->>'source_port_max' = '65535'
                then  'All TCP'
              when e ->>'protocol' = 'tcp' and e ->> 'source_port_min' = e ->> 'source_port_max'
                then  concat(e ->> 'source_port_min', '/TCP')
              when e->>'protocol' = 'udp' and e ->> 'source_port_min'  = e ->> 'source_port_max'
                then  concat(e->> 'source_port_min', '/UDP')
              when e->>'protocol' = 'tcp' and e ->> 'source_port_min' <> e->> 'source_port_max'
                then  concat(e ->> 'source_port_min', '-', e ->> 'source_port_max', '/TCP')
              when e->>'protocol' = 'udp' and e ->> 'source_port_min' <> e->> 'source_port_max'
                then  concat(e ->> 'source_port_min', '-', e ->> 'source_port_max', '/udp')
              else concat('Procotol: ', e->>'protocol')
        end as rule_description,

        a ->> 'id' as subnet_id
      from
        ibm_is_network_acl,
        jsonb_array_elements(rules) as e,
        jsonb_array_elements(subnets) as a
      where
        vpc ->> 'crn' = $1
        and e ->> 'direction' = 'outbound'
    )

    -- Subnet Nodes
    select
      distinct a.subnet_id as id,
      s.name as title,
      'subnet' as category,
      null as from_id,
      null as to_id,
      0 as depth
    from aces as a left join ibm_is_subnet as s on s.id = a.subnet_id

    -- ACL Nodes
    union select
      distinct s.network_acl_id as id,
      acl.name as title,
      'nacl' as category,
      null as from_id,
      null as to_id,
      1 as depth
    from aces as s left join ibm_is_network_acl as acl on s.network_acl_id = acl.id

    -- Rule Nodes
    union select
      concat(network_acl_id, '_', rule_name) as id,
     rule_description as title,
      'rule' as category,
      null as from_id,
      null as to_id,
      2 as depth
    from aces

    -- CIDR Nodes
    union select
      distinct cidr_block as id,
      cidr_block as title,
      'cidr_block' as category,
      null as from_id,
      null as to_id,
      3 as depth
    from aces

    -- nacl -> subnet edge
    union select
      null as id,
      null as title,
      'attached' as category,
      network_acl_id as from_id,
      subnet_id as to_id,
      null as depth
    from aces

    -- rule -> NACL edge
    union select
      null as id,
      null as title,
      rule_action as category,
      concat(network_acl_id, '_', rule_name) as from_id,
      network_acl_id as to_id,
      null as depth
    from aces

    -- ip -> rule edge
    union select
      null as id,
      null as title,
      rule_action as category,
      cidr_block as from_id,
      concat(network_acl_id, '_', rule_name) as to_id,
      null as depth
    from aces

  EOQ

  param "crn" {}
}

query "ibm_is_vpc_tags" {
  sql = <<-EOQ
    select
      (trim('"' FROM tag::text)) as "User Tag"
    from
      ibm_is_vpc,
      jsonb_array_elements(tags) as tag
    where
      crn = $1
    order by
      tag;
  EOQ

  param "crn" {}
}
