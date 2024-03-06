mod "ibm_insights" {
  # Hub metadata
  title         = "IBM Cloud Insights"
  description   = "Create dashboards and reports for your IBM Cloud resources using Powerpipe and Steampipe."
  color         = "#0F62FE"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/ibm-insights.svg"
  categories    = ["ibm", "dashboard", "public cloud"]

  opengraph {
    title       = "Powerpipe Mod for IBM Cloud Insights"
    description = "Create dashboards and reports for your IBM Cloud resources using Powerpipe and Steampipe."
    image       = "/images/mods/turbot/ibm-insights-social-graphic.png"
  }

  require {
    plugin "ibm" {
      min_version = "0.1.0"
    }
  }
}
