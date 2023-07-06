FROM r-base
LABEL org.opencontainers.image.source=https://github.com/kestra-io/examples
LABEL org.opencontainers.image.description="Image with the common R libraries"
RUN R -e "install.packages('dplyr')"
RUN R -e "install.packages('arrow')"
RUN R -e "install.packages('tidyverse')"
RUN R -e "install.packages('sqldf')"