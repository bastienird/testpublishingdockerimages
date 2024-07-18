# Utiliser l'image de base R
FROM rocker/r-ver:4.2.3

# Informations sur le mainteneur
LABEL maintainer="Julien Barde <julien.barde@ird.fr>"

# Installer les bibliothèques système de base
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

# Installer les bibliothèques supplémentaires pour redland
RUN apt-get update && apt-get install -y \
    librdf0 \
    librdf0-dev \
    redland-utils && \
    apt-get clean


# ARG defines a constructor argument called RENV_PATHS_ROOT. Its value is passed from the YAML file. an initial value is setted up in case the yml does not provide one
ARG RENV_PATHS_ROOT=/root/.cache/R/renv

# Set environment variables for renv cache
ENV RENV_PATHS_CACHE=${RENV_PATHS_ROOT}

#Running the RENV_PATHS_ROOT and RENV_PATHS_CACHE to stop cache if renv.lock has changed
RUN echo "RENV_PATHS_ROOT=${RENV_PATHS_ROOT}"
RUN echo "RENV_PATHS_CACHE=${RENV_PATHS_CACHE}"

ARG RENV_LOCK_HASH
RUN echo "RENV_LOCK_HASH=${RENV_LOCK_HASH}"

# Set environment variables for renv cache
RUN mkdir -p ${RENV_PATHS_ROOT}

# Set the working directory
WORKDIR /root/testpublishingdockerimages

# Copy renv configuration and lockfile
COPY renv.lock ./
# COPY .Rprofile ./ # not usefull as we run renv::activate() before starting the app but can be
COPY renv/activate.R renv/
COPY renv/settings.json renv/
RUN ls -la #listing the files for diagnostics
RUN ls -la renv #listing the files for diagnostics

# Restaurer les packages renv
RUN R -e "renv::activate()" # used to setup the environement (with the path cache)
RUN R -e "renv::restore()" # restoring the packages

# Create data repository
RUN mkdir -p data 
RUN ls -la ./data #listing the files for diagnostics

#Running the DOI_CSV_HASH to stop cache if DOI_CSV_HASH has changed (if DOI.csv has changed)
RUN echo "DOI_CSV_HASH=${DOI_CSV_HASH}"


COPY data/DOI2.csv ./data/DOI2.csv # copy the csv containing the data to donwload
COPY update_data.R ./update_data.R # copy the script downloading the data from the csv

# Ajouter une étape pour lister les fichiers après copie
RUN ls -la ./data #listing the files for diagnostics
RUN ls -la #listing the files for diagnostics

# Exécuter le script de traitement des données
RUN Rscript update_data.R #downloading the data (cached if data/DOI.csv did not change)

# Copy the rest of the application code
COPY . .

# Expose port 3838 for the Shiny app
EXPOSE 3838

# Create directories for configuration
RUN mkdir -p /etc/testpublishingdockerimages/

RUN Rscript global.R

# Define the entry point to run the Shiny app
CMD ["R", "-e", "shiny::runApp('/root/testpublishingdockerimages', port=3838, host='0.0.0.0')"]
