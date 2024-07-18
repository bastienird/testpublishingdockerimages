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

# Set environment variables for renv cache
ARG RENV_PATHS_ROOT=/root/.cache/R/renv
ENV RENV_PATHS_CACHE=${RENV_PATHS_ROOT}

# Define the build argument for the hash of renv.lock
ARG RENV_LOCK_HASH
ARG DOI_CSV_HASH

# Echo the environment variables for debugging
RUN echo "RENV_PATHS_ROOT=${RENV_PATHS_ROOT}"
RUN echo "RENV_PATHS_CACHE=${RENV_PATHS_CACHE}"
RUN echo "RENV_LOCK_HASH=${RENV_LOCK_HASH}"
RUN echo "DOI_CSV_HASH=${DOI_CSV_HASH}"

# Create the renv cache directory
RUN mkdir -p ${RENV_PATHS_ROOT}

# Set the working directory
WORKDIR /root/testpublishingdockerimages

# Copy the data CSV and the update script
COPY --chown=root:root data/DOI2.csv ./data/DOI2.csv
COPY --chown=root:root update_data.R ./update_data.R

# List files after copying for diagnostics
RUN ls -la ./data
RUN ls -la

# Run the data update script
RUN Rscript update_data.R

# Copy renv configuration and lockfile
COPY renv.lock ./
COPY renv/activate.R renv/
COPY renv/settings.json renv/

# List the renv files for diagnostics
RUN ls -la renv

# Restore renv packages
RUN R -e "renv::activate()"
RUN R -e "renv::restore()"

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
