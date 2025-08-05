library(shiny)

ui <- fluidPage(
  tags$head(
    tags$link(
      href = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css",
      rel = "stylesheet"
    ),

    tags$link(
        href = "styles.css",
        rel = "stylesheet",
        type = "text/css"
    ),
    includeCSS("www/styles.css")
  ),

  # Sidebar
  div(class = "sidebar",
      h4("SICONFI"),
      hr(),
      a("Dashboard", href = "#"),
      a("Extrações", href = "#"),
      a("Relatórios", href = "#"),
      a("Sobre", href = "#")
  ),

  # Topbar
  div(class = "topbar", "API SICONFI Extrator"),

  # Main content
  div(class = "main-content container-fluid",
      
      div(class = "card-style",
          h4("Filtros de Extração"),
          fluidRow(
            column(6,
                   selectInput("endpoint", "Endpoint:",
                               choices = c("rreo", "rgf", "dca", "entes",
                                           "extrato_entregas", "msc_controle",
                                           "msc_orcamentaria", "msc_patrimonial")),

                   sliderInput("ano_range", "Período (Ano):",
                               min = 2015, max = as.numeric(format(Sys.Date(), "%Y")),
                               value = c(2023, 2024), sep = "", ticks = FALSE),

                   checkboxGroupInput("bimestres", "Bimestres:",
                                      choices = 1:6,
                                      selected = c(1, 2, 3))
            ),
            column(6,
                   selectInput("tipo_demo", "Tipo de Demonstrativo:",
                               choices = c("RREO", "RREO Simplificado")),

                   selectizeInput("ufs", "UFs (múltiplas):",
                                  choices = c(
                                    "12 - Acre", "27 - Alagoas", "13 - Amazonas", "16 - Amapá", "29 - Bahia", 
                                    "23 - Ceará", "53 - Distrito Federal", "32 - Espírito Santo", "52 - Goiás", 
                                    "21 - Maranhão", "31 - Minas Gerais", "50 - Mato Grosso do Sul", "51 - Mato Grosso", 
                                    "15 - Pará", "25 - Paraíba", "26 - Pernambuco", "22 - Piauí", "41 - Paraná", 
                                    "33 - Rio de Janeiro", "24 - Rio Grande do Norte", "11 - Rondônia", "14 - Roraima", 
                                    "43 - Rio Grande do Sul", "42 - Santa Catarina", "28 - Sergipe", 
                                    "35 - São Paulo", "17 - Tocantins"
                                  ),
                                  multiple = TRUE,
                                  selected = c("33 - Rio de Janeiro", "35 - São Paulo")),

                   textInput("anexo", "Anexo (opcional):", "")
            )
          ),
          actionButton("buscar", "Buscar", class = "btn btn-primary mt-3")
      ),

      div(class = "card-style",
          h4("Prévia dos Dados"),
          tableOutput("preview")
      )
  ),

  div(class = "download-btn",
      downloadButton("baixar", "Baixar CSV", class = "btn btn-success btn-lg"))
)

server <- function(input, output, session) {
  
  ufs <- c(
  "12 - Acre", "27 - Alagoas", "13 - Amazonas", "16 - Amapá", "29 - Bahia", 
  "23 - Ceará", "53 - Distrito Federal", "32 - Espírito Santo", "52 - Goiás", 
  "21 - Maranhão", "31 - Minas Gerais", "50 - Mato Grosso do Sul", "51 - Mato Grosso", 
  "15 - Pará", "25 - Paraíba", "26 - Pernambuco", "22 - Piauí", "41 - Paraná", 
  "33 - Rio de Janeiro", "24 - Rio Grande do Norte", "11 - Rondônia", "14 - Roraima", 
  "43 - Rio Grande do Sul", "42 - Santa Catarina", "28 - Sergipe", 
  "35 - São Paulo", "17 - Tocantins"
    )

    output$parametros_ui <- renderUI({
    req(input$endpoint)
    
    if (input$endpoint == "rreo") {
        tagList(
        sliderInput("ano_range", "Período (Ano):",
                    min = 2015, max = as.numeric(format(Sys.Date(), "%Y")),
                    value = c(2023, 2024), sep = "", ticks = FALSE),
        
        checkboxGroupInput("bimestres", "Bimestres:",
                            choices = 1:6,
                            selected = c(1, 2, 3)),
        
        selectInput("tipo_demo", "Tipo de Demonstrativo:",
                    choices = c("RREO", "RREO Simplificado")),
        
        selectizeInput("ufs", "UFs (múltiplas):",
                    choices = ufs,
                    multiple = TRUE,
                    selected = c("33 - Rio de Janeiro", "35 - São Paulo"),
                    options = list(plugins = list('remove_button'))),

        textInput("id_ente", "Código IBGE do Ente (opcional):", ""),
        textInput("anexo", "Anexo (opcional):", ""),
        
        textInput("caminho_csv", "Caminho para salvar o CSV:", value = "dados_siconfi.csv")
        )
    }
    })
}

