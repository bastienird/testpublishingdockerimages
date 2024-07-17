# Install necessary packages
library(XML)
install_github("eblondel/zen4R")
require(zen4R)
library(readr)
DOI <- read_csv("data/DOI2.csv")

extract_zenodo_metadata <- function(doi, filename, data_dir = "data") {
  
  dir <- getwd()
  # Create the data directory if it doesn't exist
  if (!dir.exists(data_dir)) {
    dir.create(data_dir)
  }
  
  # Set the working directory to the data directory
  setwd(data_dir)
  
  # Export DublinCore metadata
  zen4R::export_zenodo(doi = doi, filename = "zenodoDublincore", format = "DublinCore")
  
  # Download the required file
  zen4R::download_zenodo(doi = doi, files = filename)
  
  # Parse the Dublin Core XML file
  xml_file <- xmlTreeParse("zenodoDublincore_DublinCore.xml", useInternalNodes = TRUE)
  xml_root <- xmlRoot(xml_file)
  
  # Define namespaces if necessary
  namespace_definitions <- c(
    dc = "http://purl.org/dc/elements/1.1/"
  )
  
  # Extract metadata elements
  title <- xpathSApply(xml_root, "//dc:title", xmlValue, namespaces = namespace_definitions)
  creator <- xpathSApply(xml_root, "//dc:creator", xmlValue, namespaces = namespace_definitions)
  description <- xpathSApply(xml_root, "//dc:description", xmlValue, namespaces = namespace_definitions)[1]
  publisher <- xpathSApply(xml_root, "//dc:publisher", xmlValue, namespaces = namespace_definitions)
  date <- xpathSApply(xml_root, "//dc:date", xmlValue, namespaces = namespace_definitions)
  identifier <- xpathSApply(xml_root, "//dc:identifier", xmlValue, namespaces = namespace_definitions)[1]
  coverage <- xpathSApply(xml_root, "//dc:coverage", xmlValue, namespaces = namespace_definitions)
  if (length(coverage) == 0) { coverage <- "Undefined" }
  rights <- xpathSApply(xml_root, "//dc:rights", xmlValue, namespaces = namespace_definitions)
  
  # Create a dataframe with the extracted metadata
  metadata_df <- data.frame(
    Title = title,
    Creator = creator,
    Description = description,
    Publisher = publisher,
    Date = date,
    Identifier = identifier,
    Coverage = coverage,
    Rights = rights,
    stringsAsFactors = FALSE
  )
  
  # Reset the working directory to the original
  setwd(dir)
}

lapply(1:nrow(DOI), function(i) {
  extract_zenodo_metadata(doi = DOI$DOI[i], filename = DOI$Filename[i])
})



