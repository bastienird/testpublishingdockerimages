
# Source install script
source(here::here('install.R'))
flog.info("All libraries loaded successfully.")

# Read the DOI CSV file
DOI <- read_csv('data/DOI2.csv')
# DOI$Filename <- "global_catch_tunaatlasird_level2.csv"
load_data <- function() {
  loaded_data <- list()
  
  for (filename in DOI$Filename) {
    if(!exists(tools::file_path_sans_ext(filename))){
      
      flog.info("Loading dataset: %s", filename)
      
      base_filename <- tools::file_path_sans_ext(filename) # Remove any existing extension
      csv_file_path <- file.path('data', paste0(base_filename, '.csv'))
      rds_file_path <- file.path('data', paste0(base_filename, '.rds'))
      
      if (file.exists(csv_file_path)) {
        assign(base_filename, read_csv(csv_file_path), envir = .GlobalEnv)
        loaded_data[[base_filename]] <- read_csv(csv_file_path)
      } else if (file.exists(rds_file_path)) {
        assign(base_filename, readRDS(rds_file_path), envir = .GlobalEnv)
        loaded_data[[base_filename]] <- readRDS(rds_file_path)
      } else {
        warning(paste('File not found:', csv_file_path, 'or', rds_file_path))
      }
    } else {
      flog.info("Dataset %s already existing, no need to load it", tools::file_path_sans_ext(filename))
      
    }
  }
  
  # return(loaded_data)
}

# Load all data files
load_data()

# rm(global_catch_tunaatlasird_level2)
# Log the loading of libraries
flog.info("All datasets loaded successfully.")

# Load environment variables from file
try(dotenv::load_dot_env("connection_tunaatlas_inv.txt"))

# Create database connection pool
# Log environment variables
db_host <- Sys.getenv("DB_HOST")
db_port <- as.integer(Sys.getenv("DB_PORT"))
db_name <- Sys.getenv("DB_NAME")
db_user <- Sys.getenv("DB_USER")
db_user_readonly <- Sys.getenv("DB_USER_READONLY")
db_password <- Sys.getenv("DB_PASSWORD")

flog.info("Attempting to connect to the database with the following parameters:")
flog.info("Host: %s", db_host)
flog.info("Port: %d", db_port)
flog.info("Database Name: %s", db_name)
flog.info("User: %s", db_user)
flog.info("User readonly: %s", db_user_readonly)

# Create database connection pool
tryCatch({
  pool <- dbPool(RPostgreSQL::PostgreSQL(),
                 host = db_host,
                 port = db_port,
                 dbname = db_name,
                 user = db_user_readonly,
                 password = db_password)
  flog.info("Database connection pool created successfully.")
}, error = function(e) {
  flog.error("Failed to create database connection pool: %s", e$message)
})