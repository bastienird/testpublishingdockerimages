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
RUN R -e "install.packages('renv', repos='https://cran.r-project.org/')"

# ARG définit un argument de construction appelé RENV_PATHS_ROOT. Sa valeur est passée depuis le fichier YAML.
ARG RENV_PATHS_ROOT



# Set environment variables for renv cache
RUN mkdir -p ${RENV_PATHS_ROOT}

# Set the working directory
WORKDIR /root/testpublishingdockerimages

# Copy renv configuration and lockfile
COPY renv.lock ./
COPY .Rprofile ./
COPY renv/activate.R renv/
COPY renv/settings.json renv/
  
# Set renv cache location
ENV RENV_PATHS_CACHE ${RENV_PATHS_ROOT}

# Restore renv packages
RUN R -e "renv::activate()"
RUN R -e "renv::restore()"

# Copy the rest of the application code
COPY . .

# Expose port 3838 for the Shiny app
EXPOSE 3838

# Create directories for configuration
RUN mkdir -p /etc/testpublishingdockerimages/
  
# Define the entry point to run the Shiny app
CMD ["R", "-e", "shiny::runApp('/root/testpublishingdockerimages', port=3838, host='0.0.0.0')"]
