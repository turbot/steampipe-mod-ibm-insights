dashboard "ibm_vpc_detail" {

  title = "IBM VPC Detail"
  documentation = file("./dashboards/vpc/docs/vpc_detail.md")

  tags = merge(local.vpc_common_tags, {
    type = "Detail"
  })

  input "vpc_crn" {
    title = "Select a VPC:"
    sql   = query.ibm_vpc_input.sql
    width = 4
  }

  container {

    card {
      width = 2
      query = query.ibm_vpc_num_ips_for_vpc
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
        query = query.ibm_vpc_overview
        args  = {
          crn = self.input.vpc_crn.value
        }
      }

      table {
        title = "Tags"
        width = 6
        query = query.ibm_vpc_tags
        args  = {
          crn = self.input.vpc_crn.value
        }
      }

    }

    container {

      width = 6

      table {
        title = "Address Prefixes"
        query = query.ibm_vpc_address_prefixes
        args  = {
          crn = self.input.vpc_crn.value
        }
      }

      # table {
      #   title = "DHCP Options"
      #   query = query.ibm_vpc_dhcp_options
      #   args  = {
      #     crn = self.input.vpc_crn.value
      #   }
      # }

    }

  }

  container {

    title = "Subnets"

    chart {
      title = "Subnets by AZ"
      type  = "column"
      width = 4
      query = query.ibm_vpc_subnet_by_az
      args = {
        crn = self.input.vpc_crn.value
      }
    }

    table {
      query = query.ibm_vpc_subnets_for_vpc
      width = 8
      args = {
        crn = self.input.vpc_crn.value
      }
    }

  }

  table {
    title = "Cloud Service Endpoint Source Addresses"
    query = query.ibm_vpc_cse_source_ip_addresses
    args = {
      crn = self.input.vpc_crn.value
    }
  }


  table {
    title = "Default Route Tables"
    query = query.ibm_vpc_default_route_tables
    args = {
      crn = self.input.vpc_crn.value
    }
  }

  table {
    title = "Default Security Group"
    query = query.ibm_vpc_default_security_group
    args = {
      crn = self.input.vpc_crn.value
    }
  }

  table {
    title = "Default NACL"
    query = query.ibm_vpc_default_network_acl
    args = {
      crn = self.input.vpc_crn.value
    }
  }

}

query "ibm_vpc_input" {
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

query "ibm_vpc_num_ips_for_vpc" {
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

query "ibm_vpc_subnets_for_vpc" {
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

query "ibm_vpc_default_security_group" {
  sql = <<-EOQ
    select
      default_security_group ->> 'name' as "Group Name",
      default_security_group ->> 'id' as "Group ID",
      default_security_group ->> 'href' as "HREF",
      default_security_group ->> 'crn' as "CRN"
    from
      ibm_is_vpc
    where
      crn = $1
    order by
      default_security_group ->> 'name';
  EOQ

  param "crn" {}
}

query "ibm_vpc_default_route_tables" {
  sql = <<-EOQ
    select
      default_routing_table ->> 'name' as "Route Table Name",
      default_routing_table ->> 'id' as "Route Table ID",
      default_routing_table ->> 'href' as "HREF"
    from
      ibm_is_vpc
    where
      crn = $1
    order by
      default_routing_table -> 'name';
  EOQ

  param "crn" {}
}

query "ibm_vpc_default_network_acl" {
  sql = <<-EOQ
    select
      default_network_acl ->> 'name' as "Name",
      default_network_acl ->> 'id' as "ID",
      default_network_acl ->> 'href' as "HREF",
      default_network_acl ->> 'crn' as "CRN"
    from
      ibm_is_vpc
    where
      crn = $1
    order by
      default_network_acl ->> 'name';
  EOQ

  param "crn" {}
}

query "ibm_vpc_overview" {
  sql = <<-EOQ
    select
      id as "ID",
      title as "Title",
      status as "Status",
      resource_group ->> 'name' as "Resource Group",
      region as "Region",
      account_id as "Account ID",
      href as "HREF",
      crn as "CRN"
    from
      ibm_is_vpc
    where
      crn = $1
  EOQ

  param "crn" {}
}

query "ibm_vpc_address_prefixes" {
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

query "ibm_vpc_subnet_by_az" {
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

query "ibm_vpc_cse_source_ip_addresses" {
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

query "ibm_vpc_tags" {
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