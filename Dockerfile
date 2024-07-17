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
    cmake \
    librdf0 \
    librdf0-dev \
    redland-utils


# Définir l'argument de construction pour le chemin du cache renv
ARG RENV_PATHS_ROOT=/root/.cache/R/renv

# Définir les variables d'environnement pour le cache renv
ENV RENV_PATHS_CACHE=${RENV_PATHS_ROOT}

# Diagnostiquer la valeur de la variable
RUN echo "RENV_PATHS_ROOT=${RENV_PATHS_ROOT}"
RUN echo "RENV_PATHS_CACHE=${RENV_PATHS_CACHE}"

# Créer le répertoire du cache renv
RUN mkdir -p ${RENV_PATHS_ROOT}

# Définir le répertoire de travail
WORKDIR /root/testpublishingdockerimages

# Copier les fichiers renv et lister les fichiers pour le diagnostic
COPY renv.lock ./
COPY .Rprofile ./
COPY renv/activate.R renv/
COPY renv/settings.json renv/
RUN ls -la
RUN ls -la renv

# Restaurer les packages renv
RUN R -e "renv::activate()"
RUN R -e "renv::restore()"

# Créer le répertoire data et lister les fichiers pour le diagnostic
RUN mkdir -p data
RUN ls -la ./data

# Copier les données et le script de traitement
COPY data/DOI2.csv ./data/DOI2.csv
COPY update_data.R ./update_data.R

# Ajouter une étape pour lister les fichiers après copie
RUN ls -la ./data
RUN ls -la

# Exécuter le script de traitement des données
RUN Rscript update_data.R

# Copier le reste du code de l'application
COPY . .

# Exposer le port 3838 pour l'application Shiny
EXPOSE 3838

# Créer des répertoires pour la configuration
RUN mkdir -p /etc/testpublishingdockerimages/

# Définir le point d'entrée pour exécuter l'application Shiny
CMD ["R", "-e", "shiny::runApp('/root/testpublishingdockerimages', port=3838, host='0.0.0.0')"]
