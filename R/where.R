
#' @title Where is this City?
#'
#' @description An addin to test your geographical skills !
#'
#' @param mode Play mode: \code{city} or \code{country}.
#' @param area Default selected country/continent.
#' @param time Playing time, default to 60 seconds.
#' @param viewer Where to display the gadget: \code{"dialog"},
#'  \code{"pane"} or \code{"browser"} (see \code{\link[shiny]{viewer}}).
#'
#' @export
#'
#' @importFrom miniUI miniPage miniContentPanel
#' @importFrom shiny icon actionButton callModule observeEvent
#'  showNotification observe showModal modalDialog tags isolate
#'  stopApp dialogViewer browserViewer paneViewer runGadget onStop
#'
#' @examples
#' \dontrun{
#'
#' where()
#'
#' }
where <- function(mode = getOption("where.mode", default = "city"),
                  area = getOption("where.area"),
                  time = getOption("where.playtime", default = 60),
                  viewer = getOption(x = "where.viewer", default = "dialog")) {

  mode <- match.arg(arg = mode, choices = c("city", "country"))

  options("where.playtime" = time)
  if (!is.null(area)) {
    if (area %in% get_continents()[[1]]) {
      options("where.code" = area)
    } else {
      code <- get_country_code(area)
      code <- tolower(code)
      options("where.code" = code)
    }
  }

  ui <- miniPage(
    # style sheet
    tags$link(rel="stylesheet", type="text/css", href="where/styles.css"),
    # title
    tags$div(
      class="gadget-title dreamrs-title-box",
      tags$h1(icon("map-marker"), "Where is this ", mode, "?", class = "dreamrs-title"),
      actionButton(
        inputId = "close", label = "Close",
        class = "btn-sm pull-left"
      ),
      tags$div(
        class = "pull-right",
        choose_area_ui(id = "area", class = "btn-sm")
      )
    ),
    # body
    miniContentPanel(
      padding = 0,
      where_ui(id = "map"),
      time_ui(id = "time")
    )
  )

  server <- function(input, output, session) {

    area_r <- callModule(choose_area_server, id = "area", launch = TRUE, mode = mode)
    time_r <- callModule(time_server, id = "time", rv_area = area_r)
    if (mode == "city") {
      where_r <- callModule(where_city_server, id = "map", rv_area = area_r, rv_time = time_r)
    } else {
      where_r <- callModule(where_country_server, id = "map", rv_area = area_r, rv_time = time_r)
    }

    observeEvent(where_r$timestamp, {
      if (!is.null(where_r$points) && where_r$points >= 0 & time_r$time > 0) {
        showNotification(
          ui = sprintf("%s points! Total: %s", where_r$points, where_r$total),
          duration = 2,
          type = ifelse(where_r$points < 1, "error", "message")
        )
      }
    })

    observe({
      if (time_r$time < 1) {
        showModal(modalDialog(
          title = "Time elapsed!",
          fade = FALSE,
          easyClose = FALSE,
          tags$div(
            style = "text-align: center;",
            tags$br(),
            tags$h4("You played with:", isolate(area_r$area)),
            tags$br(),
            tags$h2("You scored", tags$b(isolate(where_r$total)), "points!"),
            tags$h5("(", isolate(where_r$n_played),
                    ifelse(mode == "city", "cities", "countries"), "in",
                    getOption("where.playtime"), "seconds )")
          )
        ))
      }
    })

    observeEvent(input$close, stopApp())
    onStop(stopApp)
  }

  if (viewer == "dialog") {
    viewer_opts <- dialogViewer(
      "Test your geography skills!",
      width = 1000, height = 750
    )
  } else if (viewer == "pane") {
    viewer_opts <- paneViewer(minHeight = "maximize")
  } else {
    viewer_opts <- browserViewer()
  }
  runGadget(app = ui, server = server, viewer = viewer_opts)
}



