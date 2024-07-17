server <- function(input, output) {
  
  # Plot the histogram
  output$distPlot <- renderPlot({
    x    <- faithful[, 2] 
    bins <- seq(min(x), max(x), length.out = input$bins + 1)
    
    hist(x, breaks = bins, col = 'darkgray', border = 'white',
         xlab = 'Waiting time to next eruption (in mins)',
         main = 'Histogram of waiting times')
  })
  
  # Render the selected dataset table
  output$dataTable <- renderTable({
    req(input$dataset)
    head(loaded_data[[input$dataset]])
  })
}
