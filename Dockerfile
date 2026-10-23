FROM rocker/r-ver:4.3.3

# Install ALL system dependencies needed for R packages
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libgit2-dev \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Use renv-style cache-friendly install
ENV R_LIBS_USER=/opt/R/library
RUN mkdir -p /opt/R/library && chmod 777 /opt/R/library

WORKDIR /app

# Install R packages first (cache layer)
RUN Rscript -e 'install.packages(c(
    "shiny", "bslib", "bsicons", "htmltools",
    "dplyr", "readr", "janitor", "lubridate",
    "ggplot2", "plotly", "DT", "scales",
    "purrr", "stringr", "tibble"
), repos="https://cloud.r-project.org", lib="/opt/R/library", Ncpus=4)'

# Copy app files
COPY . .

# Ensure data directory exists
RUN mkdir -p data

# Download KEV data if not present
RUN if [ ! -f data/known_exploited_vulnerabilities.csv ]; then \
      Rscript -e 'download.file("https://www.cisa.gov/sites/default/files/csv/known_exploited_vulnerabilities.csv", "data/known_exploited_vulnerabilities.csv")'; \
    fi

# Set library path
ENV R_LIBS_USER=/opt/R/library

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

# Run app
CMD ["R", "-e", "shiny::runApp('/app', port=8080, host='0.0.0.0', launch.browser=FALSE)"]
