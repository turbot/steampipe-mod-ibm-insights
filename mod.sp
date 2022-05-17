mod "ibm_insights" {
  # hub metadata
  title         = "IBM Cloud Insights"
  description   = "Create dashboards and reports for your IBM Cloud resources using Steampipe."
  color         = "#0F62FE"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/ibm-insights.svg"
  categories    = ["ibm", "dashboard", "public cloud"]

  opengraph {
    title       = "Steampipe Mod for IBM Cloud Insights"
    description = "Create dashboards and reports for your IBM Cloud resources using Steampipe."
    image       = "/images/mods/turbot/ibm-insights-social-graphic.png"
  }

  require {
    steampipe = "0.13.1"
    plugin "ibm" {
      version = "0.1.0"
    }
  }
}
