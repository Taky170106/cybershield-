FROM rocker/r-ver:4.3.3

# Install system dependencies
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
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set R library path
ENV R_LIBS_USER=/opt/R/library
RUN mkdir -p /opt/R/library && chmod 777 /opt/R/library

WORKDIR /app

# Install R packages
RUN Rscript -e 'install.packages(c(
    "shiny", "bslib", "bsicons", "htmltools",
    "dplyr", "readr", "janitor", "lubridate",
    "ggplot2", "plotly", "DT", "scales",
    "purrr", "stringr", "tibble",
    "tidyr", "jsonlite"
), repos="https://cloud.r-project.org", lib="/opt/R/library", Ncpus=4)'

# Copy app files
COPY . .

# Ensure data directory exists and has data
RUN mkdir -p data

# Download KEV data if not present
RUN if [ ! -f data/known_exploited_vulnerabilities.csv ]; then \
      echo "Downloading KEV data..." && \
      curl -sL "https://www.cisa.gov/sites/default/files/csv/known_exploited_vulnerabilities.csv" \
        -o data/known_exploited_vulnerabilities.csv; \
    fi

# Verify data file exists
RUN test -f data/known_exploited_vulnerabilities.csv || \
    (echo "ERROR: Data file missing" && exit 1)

# Expose port
EXPOSE 8080

# Run app
CMD ["R", "-e", "shiny::runApp('/app', port=8080, host='0.0.0.0', launch.browser=FALSE)"]
