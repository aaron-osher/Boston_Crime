

  dashboardPage(
    dashboardHeader(title = "BOS Crime Dashboard"),
    dashboardSidebar(
      sidebarMenu(id = "tabs",
                  menuItem("Maps", tabName = "Maps", icon = icon("map")),
                  menuItem("Forecast", tabName = "Forecast", icon = icon("chart-line")),
                  menuItem("Heatmap", tabName = "Heatmap", icon = icon("th")),
                  menuItem("Clusters", icon = icon("shapes"),
                           menuSubItem("Hierarchical Clusters", tabName = "Clusters"),
                           menuSubItem("Kmeans", tabName = "kmeans")
                  ),
                  menuItem("Data Table", tabName = "Data", icon = icon("table")),
                  menuItem("About", tabName = "About", icon = icon("question-circle"))
      ),
      conditionalPanel('input.tabs == "Heatmap" || input.tabs == "Clusters" ||
                       input.tabs == "kmeans"',
                       numericInput("bin_n", "Number of bins per axis:", value = 30,
                                    min = 1, max = 100)
      ),
      conditionalPanel('input.incident_toggle == true',
                       pickerInput("incidentTypeDetailed", 
                                   "Incident Type (Detailed)", 
                                   choices = incidents,
                                   selected = incidents,
                                   multiple = T,
                                   options = pickerOptions(
                                     actionsBox = TRUE,
                                     deselectAllText = "None",
                                     selectAllText = "All",
                                     dropupAuto = F))
      ),
      conditionalPanel('input.incident_toggle == false',
                       pickerInput("incidentType", 
                                   "Incident Type", 
                                   choices = incidents_group,
                                   selected = incidents_group,
                                   multiple = T,
                                   options = pickerOptions(
                                     actionsBox = TRUE,
                                     deselectAllText = "None",
                                     selectAllText = "All",
                                     dropupAuto = F))
      ),
      materialSwitch("incident_toggle", "Detailed Incidents", right=T),
      pickerInput("neighborhood", 
                  "Neighborhood", 
                  choices = neighborhoods,
                  selected = neighborhoods,
                  multiple = T,
                  options = list(
                    `actions-box` = TRUE,
                    `deselect-all-text` = "None",
                    `select-all-text` = "All",
                    dropupauto = F)
      ),
      conditionalPanel('input.tabs == "Forecast" || input.tabs == "Data"', 
                       checkboxInput("nolatlong", 
                                     "Include incidents with\nno longitude/latitude",
                                     value = F)
      ),
      dateRangeInput("dateRange", "Date Range:",                  
                     start  = "2015-06-15",
                     end    = "2019-05-01",
                     min    = "2015-06-15",
                     max    = "2019-05-01",
                     format = "mm/dd/yyyy",
                     separator = " to ", 
                     width = NULL,
                     autoclose = TRUE),
      pickerInput("weekdays", 
                  "Days of Week", 
                  choices = c("Sunday","Monday","Tuesday","Wednesday",
                              "Thursday","Friday","Saturday"), 
                  selected = c("Sunday","Monday","Tuesday","Wednesday",
                               "Thursday","Friday","Saturday"),
                  multiple = T,
                  options = list(
                    `actions-box` = TRUE,
                    `deselect-all-text` = "None",
                    `select-all-text` = "All")
      ),
      sliderInput("timeRange", label = "Hour range",
                  min = 0,
                  max = 24,
                  value = c(0,24),
                  step = 1)
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "Maps",
              h2("Police Incident Reports by Neighborhood"),
              materialSwitch("sq_mile_toggle", "Per Square Mile", right=T),
              textOutput("sq_mile_header", container = h2),
              ggiraphOutput("districtPlot") %>% withSpinner(),
              fluidRow(
                column(10, align = "center", offset = 1,
                       conditionalPanel("output.datatab != null",
                                        downloadButton("download_datatab", 
                                                       "Download Selected Data")
                       ),
                       dataTableOutput("datatab"))
              )
      ),
      tabItem(tabName = "Forecast",
              h2("Time Series Forecast for Selected Neighbourhood and Crime type"),
              div(
                p("Forecast fit via the ", code("auto.arima"), 
                  " function from the ", code("forecast"),
                  " package (Hyndman et al., 2019) in ",code("R"), 
                  " using the default settings for 
                  rapid estimation.")
                ),
              plotOutput("autoArimaMonthPlot") %>% withSpinner(),
              fluidRow(
               box(width = 6,
                div(
                  h3("PLEASE NOTE", align="center"),
                  p(HTML("<u><b>Forecasts are provided for 
                         demonstration purposes only</b></u> and neither 
                         present nor imply any guarantees or claims to accuracy.")),
                  p(HTML("<b>For more information on time-series analysis, see:</b>"),
                    align = "center"),
                  p(HTML("Hyndman, R.J., & Athanasopoulos, G. (2018) Forecasting: 
                         principles and practice, 2nd edition, OTexts: Melbourne, 
                         Australia. <a href='http://OTexts.com/fpp2' target='_blank'>
                         OTexts.com/fpp2</a>. 
                        ")),
                  p(HTML("Hyndman R, Athanasopoulos G, Bergmeir C, Caceres G, Chhay L, 
                         O'Hara-Wild M, Petropoulos F, Razbash S, Wang E, 
                         Yasmeen F (2019). forecast: Forecasting functions 
                         for time series and linear models. R package version 8.7, 
                         <a href='http://pkg.robjhyndman.com/forecast' target='_blank'>
                         http://pkg.robjhyndman.com/forecast</a>."))
                 )
                ),
                box(width = 6,
                    numericInput("forecast_size", "Number of Months ahead to Forecast",
                                 value = 24, min = 2, max = 100, step = 1),
                    switchInput("abovezero", "Constrain to Positive Values",
                                value = T),
                    conditionalPanel("output.autoArimaMonthPlot != null",
                                     downloadButton("download_arimatab", 
                                                    "Download Model Data")
                    )
                )
              )
            ),
      tabItem(tabName = "Heatmap",
              h2("Heatmap of Incidents for Selected Data"),
              ggiraphOutput("heatmap", height = "800px") %>% withSpinner(),
              fluidRow(
                column(10, align = "center", offset = 1,
                       conditionalPanel("output.heattab != null",
                                        downloadButton("download_heattab", 
                                                       "Download Selected Data")
                       ),
                       dataTableOutput("heattab"))
              )
      ),
      tabItem(tabName = "Clusters",
              h2("Hierarchical Cluster Analysis of Included Incident Categories"),
              h3("(for Selected Data)"),
              p(HTML("<b>Note: solution can take some time to fit.</b><br><br>")),
              fluidRow(
                box(
                  numericInput("n_clust_groups", "Number of Clusters",
                               value = 5, min = 2, max = 10, step = 1),
                  numericInput("geoweight_clust", "Weight to Geographic Proximity",
                               value = .2, min = 0, max = 1, step = .1),
                  materialSwitch("hclust_silhouette", 
                                 "Produce plots for help selecting number of clusters?", 
                                 right=T)
                )
              ),
              ggiraphOutput("clustermap", height = "800px") %>% withSpinner(),
              fluidRow(
                column(10, align = "center", offset = 1,
                       conditionalPanel("output.clustertab != null",
                                        downloadButton("download_clustertab", 
                                                       "Download Selected Data")
                       ),
                       dataTableOutput("clustertab"))
              ),
              conditionalPanel('input.hclust_silhouette == true',
                               fluidRow(box(width = 12,
                                            div("The plots below provide visual aid
                                                for selecting the number of clusters
                                                to fit, and the optimal proportion of 
                                                mixing between incident-based and 
                                                geographic similarity to maximize
                                                information explained."))),
                               h3("Silhouette (incident data)"),
                               plotOutput("hclust_sil_plot") %>% withSpinner(),
                               h3("Silhouette (geographic data)"),
                               plotOutput("hclust_geo_sil_plot") %>% withSpinner(),
                               h3("Explained inertia by level of mixing"),
                               plotOutput("hclust_alpha_plot") %>% withSpinner(),
                               p("D0 = incident data, D1 = geographic data,
                                 alpha = how strongly to weight geographic proximity
                                 (0 = only consider incidents, 1 = only consider
                                 geographic distance of bins)")
              )
      ),
      tabItem(tabName = "kmeans",
              h2("Kmeans Cluster Analysis of Included Incident Categories"),
              h3("(for Selected Data)"),
              p(HTML("<b>Note: solution can take some time to fit.</b><br><br>")),
              fluidRow(
                box(
                  numericInput("kmeans_k", "Number of clusters",
                               value = 5, min = 1, step = 1),
                  materialSwitch("kmeans_silhouette", 
                                 "Produce silhouette plot for help selecting number of clusters?", 
                                 right=T)
                )
              ),
              ggiraphOutput("kmeansmap", height = "800px") %>% withSpinner(),
              fluidRow(
                column(10, align = "center", offset = 1,
                       conditionalPanel("output.kmeanstab != null",
                                        downloadButton("download_kmeanstab", 
                                                       "Download Selected Data")
                       ),
                       dataTableOutput("kmeanstab"))
              ),
              conditionalPanel('input.kmeans_silhouette == true',
                               fluidRow(box(width = 12,
                                            div("The plot below provides visual aid
                                                for selecting the number of clusters
                                                to fit."))),
                               plotOutput("kmeans_sil_plot") %>% withSpinner()
              )
        ),
      tabItem(tabName = "Data",
              fluidRow(
                column(10, align = "center", offset = 1,
                       conditionalPanel("output.alldata != null",
                                        downloadButton("download_all", 
                                                       "Download")
                       ),
                       dataTableOutput("alldata")
                )
              )
      ),
      tabItem(tabName = "About",
              fluidRow(
                column(10, align = "center", offset = 1,
                       box(
                         width = 12, align = "left",
                         h2("About this Application"),
                         p("This is a dashboard of descriptive statistics and
                           forecasts for reported police incidents in the city of 
                           Boston from June 15, 2015 through May 1, 2019. 
                           "),
                         p(HTML("The reports were generated from the open source data
                           available from 
                           <a target='_blank'
                                href='https://data.boston.gov/'>Analyze Boston</a>.")),
                         p(HTML("This application was created by -- <br>Shaswat Rajput, Joey Callahan,
                         Yan Shen, Aaron Osher <br>
                         Try it out on Github - (
                                <a target='_blank'
                                href='https://github.com/dsi-explore/EDA_final_proj'>
                                https://github.com/shaswat01</a>)."))
                       )
              )
            )
      )
     )
    )
  )

