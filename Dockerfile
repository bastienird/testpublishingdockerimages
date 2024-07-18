# Use the base R image
FROM rocker/r-ver:4.2.3

# Maintainer information
LABEL maintainer="Julien Barde <julien.barde@ird.fr>"

# Install essential system libraries
RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libudunits2-dev \
    libproj-dev \
    libgeos-dev \
    libgdal-dev \
    libv8-dev \
    libsodium-dev \
    libsecret-1-dev \
    git \
    libnetcdf-dev \
    curl \
    libjq-dev \
    cmake && \
    apt-get clean

# Install additional libraries for redland
RUN apt-get update && apt-get install -y \
    librdf0 \
    librdf0-dev \
    redland-utils && \
    apt-get clean

# Set the working directory
WORKDIR /root/testpublishingdockerimages

# Create data repository
RUN mkdir -p data 
RUN ls -la ./data # Listing the files for diagnostics

# Echo the DOI_CSV_HASH for debugging and to to stop cache if DOI2.csv has changed
ARG DOI_CSV_HASH
RUN echo "DOI_CSV_HASH=${DOI_CSV_HASH}"

# Copy the data CSV and the update script
COPY data/DOI2.csv ./data/DOI2.csv # Copy the CSV containing the data to download
COPY update_data.R ./update_data.R # Copy the script downloading the data from the CSV

# List files after copying for diagnostics
RUN ls -la ./data # Listing the files for diagnostics
RUN ls -la # Listing the files for diagnostics

# Run the data update script
RUN Rscript update_data.R # Downloading the data (cached if data/DOI.csv did not change)

# ARG defines a constructor argument called RENV_PATHS_ROOT. Its value is passed from the YAML file. An initial value is set up in case the YAML does not provide one
ARG RENV_PATHS_ROOT=/root/.cache/R/renv

# Set environment variables for renv cache
ENV RENV_PATHS_CACHE=${RENV_PATHS_ROOT}

# Echo the RENV_PATHS_ROOT and RENV_PATHS_CACHE to stop cache if renv.lock has changed
RUN echo "RENV_PATHS_ROOT=${RENV_PATHS_ROOT}"
RUN echo "RENV_PATHS_CACHE=${RENV_PATHS_CACHE}"

# Define the build argument for the hash of renv.lock
ARG RENV_LOCK_HASH
RUN echo "RENV_LOCK_HASH=${RENV_LOCK_HASH}"

# Create the renv cache directory
RUN mkdir -p ${RENV_PATHS_ROOT}

# Copy renv configuration and lockfile
COPY renv.lock ./
COPY renv/activate.R renv/
COPY renv/settings.json renv/
RUN ls -la # Listing the files for diagnostics
RUN ls -la renv # Listing the files for diagnostics

# Restore renv packages
RUN R -e "renv::activate()" # Used to setup the environment (with the path cache)
RUN R -e "renv::restore()" # Restoring the packages

# Copy the rest of the application code
COPY . .

# Expose port 3838 for the Shiny app
EXPOSE 3838

# Create directories for configuration
RUN mkdir -p /etc/testpublishingdockerimages/

# Run the global script
RUN Rscript global.R

# Define the entry point to run the Shiny app
CMD ["R", "-e", "shiny::runApp('/root/testpublishingdockerimages', port=3838, host='0.0.0.0')"]
