FROM rocker/r-ver:4.3.2

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
    && rm -rf /var/lib/apt/lists/*

# Set library path to user directory
ENV R_LIBS_USER=/opt/R/library
RUN mkdir -p /opt/R/library && chmod 777 /opt/R/library

# Copy app files
WORKDIR /app
COPY . .

# Install R packages
RUN Rscript -e 'install.packages(c("shiny", "bslib", "dplyr", "readr", "janitor", "lubridate", "ggplot2", "plotly", "DT", "httr2"), repos="https://cloud.r-project.org", lib="/opt/R/library")'

# Expose port
EXPOSE 8080

# Run app
CMD ["R", "-e", "shiny::runApp('/app', port=8080, host='0.0.0.0')"]
