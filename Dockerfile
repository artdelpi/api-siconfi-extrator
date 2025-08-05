FROM rocker/shiny:latest

# Instala pacotes 
RUN install2.r --error \
    shiny \
    httr \
    jsonlite \
    dplyr \
    readr

# Copia os arquivos da aplicação
COPY . /srv/shiny-server/

# Permissões
RUN chown -R shiny:shiny /srv/shiny-server

# Expondo a porta padrão
EXPOSE 3838

# Roda o shiny server
CMD ["/usr/bin/shiny-server"]