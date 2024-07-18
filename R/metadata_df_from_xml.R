
metadata_df_from_xml <- function(xmlValue) {
  
  # Parse the Dublin Core XML file
  xml_file <- xmlTreeParse(xmlValue, useInternalNodes = TRUE)
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
  return(metadata_df)

}
