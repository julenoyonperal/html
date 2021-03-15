########################################################################
###############       Packages        ##################################
########################################################################


library(shiny)
library(shinyalert)
library(tidyverse)
library(odbc)
library(lubridate)
library(tidyr)
library(dplyr)
library(dbplyr)
library(shinyWidgets)
library(xlsx)
library(reshape2)

########################################################################
###############       Parameters      ##################################
########################################################################

# to set up the connection if you are locally or on the shiny server

if( Sys.info()[["sysname"]] == "Windows" ){

  out = "L:\\Analytics\\ShinyServer\\Pop counts\\"
  path_template = "L:\\Analytics\\Julen\\LDrive Git\\shinyapps\\Pop counts\\Template.xlsx"
  #path_template = "L:\\Analytics\\Julen\\Jira_Dev\\4_Shiny_app_pop_counts\\Template\\Template.xlsx"
  source("L:\\Analytics\\Julen\\LDrive Git\\shinyapps\\Pop counts\\function_to_select_lw_ftm_sql.R") 
  
  con <- dbConnect(odbc::odbc()
                   , dsn = "UKVertica"
                   , uid = "svc_sas"
                   , bigint = "integer64"
                   , pwd = "cover-z*wgNjQ")


} else {

  # Location in the Shiny server
  out = "/media/ShinyServer/Pop counts/"
  path_template = "/srv/shiny-server/test/Pop counts/Template.xlsx"
  source(here::here("function_to_select_lw_ftm_sql.R")) 

  con = dbConnect(odbc::odbc()
                    , driver = "Vertica"
                    , server = "10.221.185.11"
  				          , port = 5433
                    , database = "PVCDW"
  			            , uid = "svc_sas"
                    , pwd = "cover-z*wgNjQ"
                    , bigint = "integer")
}

location_for_user = "L:/Analytics/ShinyServer/Pop counts/"


########################################################################
###############       Functions      ###################################
########################################################################


# To write a cleaner log file
step_selected = function (step) {
  return(str_glue(
"\n\n
|-----------------------------------------------------|\n
|--------------     Step {step}    ------------------------|\n
|-----------------------------------------------------|\n\n\n"

))
}


########################################################################
#############      Pop Counts app     ##################################
########################################################################

ui = fluidPage(
  
    setBackgroundColor(
    # color = c("#F7FBFF", "#2171B5")
     color = c("#FFE5B4")
    #gradient = "radial",
    #direction = c("top", "left")
  ),

    tags$head(tags$style(
    HTML('


         #sidebar {
            background-color: #73C2FB;
        }


         #button{
            background-color: #73C2FB;
         }

         #select{
            background-color: #73C2FB;
         }



        body, input, text, label { 
          body: "#F7FBFF";
          font-family: "Arial";
        }')
  )),
  
  # Application title
  # titlePanel("Pop Counts"),
  HTML('<div class="header">
  <h1><font size="15" color="green"> Pop Counts </font></h1>
  </div>'),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    
    
    sidebarPanel(
      id = "sidebar",
      
      useShinyalert(),
      
      shinyjs::useShinyjs(),
      
      textInput("text", label = h3("Select the merchant name"), value = NULL),
      
      dateInput("date1", "Select the date:", value = get_last_day_of_data(Sys.Date())),
      
      fileInput("file1", "Choose a competitor list",
                multiple = FALSE,
                accept = c("text/csv",
                         "text/comma-separated-values,text/plain",
                         ".csv")),
      
      actionButton("Load", "Load the File"),
      
      shinyjs::hidden(actionButton("run_analysis", "Run the analysis"))

    )
      
      
      
                 ,
mainPanel(
  tabsetPanel(
        tabPanel("Location of the output",
                                    textOutput("query_text"),
                                    tags$style("#query_text{color: Blue;
                                                            font-size: 12px;
                                                            font-style: italic;
                                                             }"),
                                    textOutput("query_date"),
                                                     tags$style("#query_date{color: Blue;
                                                            font-size: 12px;
                                                            font-style: italic;
                                                             }"),
                                    textOutput("query_date_2"),
                 
                                                     tags$style("#query_date_2{color: Blue;
                                                            font-size: 12px;
                                                            font-style: italic;
                                                             }"),
                                    textOutput("query_date_3"),
                                                     tags$style("#query_date_3{color: Blue;
                                                            font-size: 12px;
                                                            font-style: italic;
                                                             }"),
                                    textOutput("query_date_4"),
                                                     tags$style("#query_date_4{color: Blue;
                                                            font-size: 12px;
                                                            font-style: italic;
                                                             }"),
                                    htmlOutput("location_output"),
                                    tags$style("#location_output{color: Green;
                                                              font-size: 15px;
                                                              font-style: italic;
                                                             }")
        )
        ,tabPanel("Competitor list",
                                    tableOutput("my_output_data")
        )

    )
)))



server = function(input, output, session) {

      
  #### Step 1: Check that we have access to the server
  
  # Connect to the database 
  


  
  # # Write a function to show message if error
  show_condition <- function(code) {
   tryCatch(code,
     error = function(c) "error",
     warning = function(c) "warning",
     message = function(c) "message"
   )}
   
 
  # # Chech if i can have one row from the table that we are going to use
   a = show_condition ( dbGetQuery(con, "select * from cdw.vft_merchant limit 1") )
   
  # # if a returns as a caracter it means that a = "error" if not it would be a list.
   if( typeof(a) == "character") {
               shinyalert("Oops!", "At this moment the database is unavailable, 
                          please try it later or contact
                          UKAdvertiserAnalytics@cardlytics.com ", type = "warning")
     }else{}

  
  #### Step 2: Chech that the name doesn't have any special carateres.  
  observeEvent(input$text,
    if( grepl('[[:punct:]]', input$text) == TRUE ){
            shinyalert("Oops!", 
                       " You have included special carateres,
                         please remove all the spceial caracteres", type = "warning")
    }
  )
  
    #### Step 3: Show the run button only if there isn't any error
  toListen <- reactive({
    list(input$text,input$Load)
  })
   
  #### Step 4: Create the dates
  df = eventReactive(input$date1, {
            EndCY <- ymd(input$date1)
            StartCY <- ymd(EndCY-7*51) 
            StartLY <- ymd(EndCY-7*103) 
            return(c(EndCY, StartCY, StartLY))
      })
  
 

  ### Step 5: import the competior list. It will allow only 10 distinct merchants
  data1 <- reactive({
    if ( input$Load == 0) {return()}
       inFile <- input$file1
    if ( is.null(inFile) ) {return(NULL)}

    isolate({ 
    input$Load
    my_data <- read.csv(inFile$datapath)
    unique_merchant = unique(my_data$merchant)
    


    })
    
    if ( length(unique_merchant) > 10) {
      shinyalert("Oops!", "There are more than 10 unique merchant names, 
                            please review the competitor list", type = "error")
      my_data = data.frame()
    }else{
        my_data = my_data
      
      }

    my_data
    
  })
  
  output$my_output_data <- renderTable({data1()},include.rownames=FALSE)  

  observeEvent(toListen(),
    if (input$text == "" || input$Load == 0 || !isTruthy(data1()) || grepl('[[:punct:]]', input$text) == TRUE)
      shinyjs::hide("run_analysis")
    else
      shinyjs::show("run_analysis")
  )

  ### Step 6: If all the previous steps are done correctly, it will show the "run"
  observeEvent(input$run_analysis, {

   # Create expresions to write in the log file 
    log_file_1 = reactive({cat(file=stderr(), 
                                str_glue("{step_selected(1)} The user is running the analysis"),"\n") })
    
    log_file_2 = reactive({cat(file=stderr(), 
                                str_glue("{step_selected(2)} The user has created the following locations:
                                            {out_merchant}
                                            {out_merchant_date}"),"\n") })
    
    log_file_3 = reactive({cat(file=stderr(), 
                                str_glue("{step_selected(3)} The Merchant list has: {nrow(comp)} rows"),"\n") })
    
    log_file_4 = reactive({cat(file=stderr(), 
                                str_glue("{step_selected(4)} Loading data to vertica"),"\n") })
    
    log_file_5 = reactive({cat(file=stderr(), 
                                str_glue("{step_selected(5)} Doing query 1 in Vertica"),"\n") })
    
    log_file_6 = reactive({cat(file=stderr(), 
                                str_glue("{step_selected(6)} Doing query 2 in Vertica"),"\n") })
    
    log_file_7 = reactive({cat(file=stderr(), 
                                str_glue("{step_selected(7)}ftm has {nrow(ftm)} rows
                                                            ftm_weekly has {nrow(ftm_weekly)} rows"),"\n") })
        
    log_file_8 = reactive({cat(file=stderr(), 
                                str_glue("{step_selected(8)} Manipulating data in R"),"\n") })
    
    log_file_9 = reactive({cat(file=stderr(), 
                                str_glue("{step_selected(9)} Exporting data to excel"),"\n") })
     
    log_file_1()   
    withProgress(message = 'Step', max = 15, value = 0, {
   
    incProgress(1, detail = "1/6 - Creating the folders")
    Sys.sleep(1)
    
    # Create some path for the outputs  
    out_merchant =  str_glue("{out}{input$text}")
    out_merchant_date = str_glue("{out}{input$text}/{format(Sys.time(), '%F')}")
    log_file_2()
    out_to_show_to_the_user = str_glue("{location_for_user}{input$text}/{format(Sys.time(), '%F')}")
    
    # Create folder with the merchant name 
    ifelse(!dir.exists(out_merchant), dir.create(out_merchant), FALSE) 
    
    # In the merchant folder, create a folder with date and time 
    ifelse(!dir.exists(out_merchant_date),  dir.create(out_merchant_date), FALSE)
     
    EndCY = df()[[1]]
    StartCY = df()[[2]]
    StartLY = df()[[3]]
    
    ## Import file
    comp = data1()
    log_file_3()
    
    ## temporarty table name
    schema_name = "temp"
    user_name = Sys.info()[["user"]]
    tb_name_in_vertica = str_glue(user_name,"_pop_counts_comps")
    competitors = str_glue(schema_name, ".", tb_name_in_vertica)
    
    log_file_4()
    # Remove table if exist
    dbGetQuery(con, str_glue(" DROP TABLE IF EXISTS {schema_name}.{tb_name_in_vertica}" ))

    incProgress(2, detail = "2/6 - Uploading data to Vertica")
    Sys.sleep(2)

    # upload to vertica
    dbWriteTable(con,
                name = DBI::Id(schema = schema_name,
                                name = tb_name_in_vertica),
                 overwrite = TRUE,
                 comp)
    
    
    
    
    incProgress(3, detail = "3/6 - Working with Vertica - query 1")
    log_file_5()
    ftm = dbGetQuery(con, str_glue(
        "select case when weekstartdt between '{StartCY}' and '{EndCY}' then 'ThisYear' else 'LastYear' end as Year,
                b.merchant,
                sum(amount) as spend,
                sum(trips) as trips,
                count(distinct cdwcustomerid) as customers, count(distinct weekstartdt) as weeks
        from cdw.vft_merchant a
        inner join {competitors} as b
              on a.segmentid = b.segmentid
        where weekstartdt between '{StartLY}' and '{EndCY}'
              and a.institutionid in (2,118)
        group by case when weekstartdt between  '{StartCY}' and '{EndCY}' then 'ThisYear' else 'LastYear' end,b.merchant"
        ))


    incProgress(4, detail = "4/6 - Working with Vertica - query 2")
    log_file_6()
    ftm_weekly = dbGetQuery(con, str_glue("
      select weekstartdt,
              b.merchant,
              sum(a.amount) as spend,
              sum(a.trips) as trips,
              count(distinct a.cdwcustomerid) as count
      from cdw.vft_merchant a
      inner join {competitors} as b
            on a.segmentid = b.segmentid
      where weekstartdt between '{StartLY}' and '{EndCY}'
            and a.institutionid in (2,118)
      group by  weekstartdt,b.merchant"))

    log_file_7()
    incProgress(5, detail = "5/6 - Formatting tables")
    Sys.sleep(1)
    
    final_grouped <- ftm_weekly %>% mutate(weekstartdt2 = ymd(weekstartdt))


    
    final_grouped = data.frame(final_grouped)
    ftm = data.frame(ftm)
    
    # select unique merchant
    
    log_file_8()
    # Format the columnss
    
    ftm$spend = as.numeric(ftm$spend)
    ftm$trips = as.numeric(ftm$trips)
    ftm$customers = as.numeric(ftm$customers)
    
    
    final_grouped$spend = as.numeric(final_grouped$spend)
    final_grouped$trips = as.numeric(final_grouped$trips)
    final_grouped$count = as.numeric(final_grouped$count)
    final_grouped = data.frame(final_grouped)
    
    
    # Modify the weekly table to display the dates as columns
    final_grouped1 = final_grouped %>% select( weekstartdt, merchant, spend)
    final_grouped1_reshape = dcast(final_grouped1, merchant~weekstartdt, fill=0, value.var = "spend", startRow=5, row.names = FALSE)
     
    final_grouped2 = final_grouped %>% select(weekstartdt, merchant, trips)
    final_grouped2_reshape = dcast(final_grouped2, merchant~weekstartdt, fill=0, value.var = "trips", startRow=25, row.names = FALSE)

    final_grouped3 = final_grouped %>% select (weekstartdt, merchant, count)
    final_grouped3_reshape = dcast(final_grouped3, merchant~weekstartdt, fill=0, value.var = "count", startRow=45, row.names = FALSE)

    # Split the data in two because it is easier like this to create formulas in the excel.
    fmt_thisyear = subset(ftm, Year == "ThisYear")
    fmt_lastyear = subset(ftm, Year == "LastYear")


    incProgress(6, detail = "6/6 - Creating the excel")
    log_file_9()
    Sys.sleep(1)
    output_file <- str_glue({out_merchant_date},"/{format(Sys.time(), '%F %H%M%S')} {input$text}_summary.xlsx")
    
    #Read template
   
    # wb <- xlsx::loadWorkbook("L:\\Analytics\\Julen\\Jira_Dev\\10_and_11_and_12_week_04_05_2020\\Shiny_app_pop_counts\\Template\\template.xlsx")
    wb <- xlsx::loadWorkbook(path_template)
     
      #Read worksheets, replace relevant worksheets with new ones 
      sheets <- xlsx::getSheets(wb)
      
        # xlsx::removeSheet(wb, sheetName = "weeklydata")
        # weeklySheet <-  xlsx::createSheet(wb, sheetName = "weeklydata")
        # xlsx::addDataFrame(final_grouped, weeklySheet)
        # 
      xlsx::removeSheet(wb, sheetName = "yearly")
      yearlySheet <-  xlsx::createSheet(wb, sheetName = "yearly")
      xlsx::addDataFrame(fmt_thisyear, sheet = yearlySheet, startCol = 1)
      xlsx::addDataFrame(fmt_lastyear, sheet = yearlySheet, startCol = 10)
      
          
      xlsx::removeSheet(wb, sheetName = "weekly")
      weeklySheet <-  xlsx::createSheet(wb, sheetName = "weekly")
      xlsx::addDataFrame(final_grouped1_reshape, sheet = weeklySheet, startRow=5)
      xlsx::addDataFrame(final_grouped2_reshape, sheet = weeklySheet, startRow=25)
      xlsx::addDataFrame(final_grouped3_reshape, sheet = weeklySheet, startRow=45)

      wb$setForceFormulaRecalculation(T)
       
      # hide two sheets
      wb$setSheetHidden(2L, 1L)
      wb$setSheetHidden(3L, 1L)
    
    #Save output
    xlsx::saveWorkbook(wb, output_file)
    print("done")

   
    shinyalert(str_glue("The report is ready"), type = "success",showConfirmButton = TRUE)
    
    output$location_output = renderText({paste("<b>Please find your Pop count located at:","<br>","  ",
                                                out_to_show_to_the_user ) })

     
      })
  #
  })

  
}


# Run the application 
shinyApp(ui = ui, server = server)


 