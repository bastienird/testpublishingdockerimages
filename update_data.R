library(XML)
library(zen4R)
library(readr)

DOI <- read_csv("data/DOI2.csv")

# Fonction pour télécharger un fichier avec une logique de reprise
download_with_retry <- function(url, destfile, retries = 3, sleep_time = 5) {
  success <- FALSE
  attempt <- 0
  while (!success && attempt < retries) {
    attempt <- attempt + 1
    tryCatch({
      download.file(url, destfile, quiet = TRUE, timeout = 600) # Augmentez le délai d'attente à 600 secondes
      if (file.info(destfile)$size > 0) {
        success <- TRUE
      } else {
        stop("File is empty after download.")
      }
    }, error = function(e) {
      cat(sprintf("Attempt %d failed: %s\n", attempt, e$message))
      Sys.sleep(sleep_time)
    })
  }
  if (!success) stop("All download attempts failed.")
}

extract_zenodo_metadata <- function(doi, filename, data_dir = "data") {
  # Créer le répertoire de données s'il n'existe pas
  if (!dir.exists(data_dir)) {
    dir.create(data_dir)
  }
  
  # Définir le répertoire de travail sur le répertoire de données
  setwd(data_dir)
  
  # Exporter les métadonnées DublinCore
  zen4R::export_zenodo(doi = doi, filename = "zenodoDublincore", format = "DublinCore")
  
  # Télécharger le fichier requis avec une logique de reprise
  record <- zen4R::get_zenodo_record(doi = doi)
  file <- record$files[[which(sapply(record$files, function(x) x$filename) == filename)]]
  download_with_retry(file$download, filename)
  
  # Analyser le fichier XML Dublin Core
  xml_file <- xmlTreeParse("zenodoDublincore_DublinCore.xml", useInternalNodes = TRUE)
  xml_root <- xmlRoot(xml_file)
  
  # Définir les espaces de noms si nécessaire
  namespace_definitions <- c(
    dc = "http://purl.org/dc/elements/1.1/"
  )
  
  # Extraire les éléments de métadonnées
  title <- xpathSApply(xml_root, "//dc:title", xmlValue, namespaces = namespace_definitions)
  creator <- xpathSApply(xml_root, "//dc:creator", xmlValue, namespaces = namespace_definitions)
  description <- xpathSApply(xml_root, "//dc:description", xmlValue, namespaces = namespace_definitions)[1]
  publisher <- xpathSApply(xml_root, "//dc:publisher", xmlValue, namespaces = namespace_definitions)
  date <- xpathSApply(xml_root, "//dc:date", xmlValue, namespaces = namespace_definitions)
  identifier <- xpathSApply(xml_root, "//dc:identifier", xmlValue, namespaces = namespace_definitions)[1]
  coverage <- xpathSApply(xml_root, "//dc:coverage", xmlValue, namespaces = namespace_definitions)
  if (length(coverage) == 0) { coverage <- "Undefined" }
  rights <- xpathSApply(xml_root, "//dc:rights", xmlValue, namespaces = namespace_definitions)
  
  # Créer un dataframe avec les métadonnées extraites
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
  
  # Réinitialiser le répertoire de travail
  setwd("..")
}

lapply(1:nrow(DOI), function(i) {
  extract_zenodo_metadata(doi = DOI$DOI[i], filename = DOI$Filename[i])
})
