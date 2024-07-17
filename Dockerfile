FROM rocker/r-ver:4.2.3

# Maintainer information
MAINTAINER Julien Barde "julien.barde@ird.fr"

# Install system libraries of general use
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
cmake

# Install cmake
RUN apt-get update && apt-get -y install 

# Install renv package
RUN R -e "install.packages('renv', repos='https://cran.r-project.org/')" # last version to keep the app updated

# ARG defines a constructor argument called RENV_PATHS_ROOT. Its value is passed from the YAML file.
ARG RENV_PATHS_ROOT

# Set environment variables for renv cache
RUN mkdir -p ${RENV_PATHS_ROOT}

# Set the working directory
WORKDIR /root/testpublishingdockerimages

# Copy renv configuration and lockfile
COPY renv.lock ./ # to record packages to install during renv::restore
# COPY .Rprofile ./ # not usefull as we run renv::activate() before starting the app but can be
COPY renv/activate.R renv/ # to activate renv and special settings (line 46)
COPY renv/settings.json renv/ # to display settings as use cache or restoring every and only packages in the lock
  
# Set renv cache location
ENV RENV_PATHS_CACHE ${RENV_PATHS_ROOT}

# Restore renv packages
RUN R -e "renv::activate()" # usefull to setup the environement (with the path cache)
RUN R -e "renv::restore()" # restoring the packages

RUN mkdir -p data

COPY update_data.R ./update_data.R # copy the script downloading the data from the csv
COPY data/DOI2.csv ./data/DOI2.csv # copy the csv containing the data to donwload

# Exécuter le script de traitement des données
RUN Rscript update_data.R.R #downloading the data (cached if data/DOI.csv did not change)

# Copy the rest of the application code
COPY . .

# Expose port 3838 for the Shiny app
EXPOSE 3838

# Create directories for configuration
RUN mkdir -p /etc/testpublishingdockerimages/
  
# Define the entry point to run the Shiny app
CMD ["R", "-e", "shiny::runApp('/root/testpublishingdockerimages', port=3838, host='0.0.0.0')"]
