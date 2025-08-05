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
                   selectInput("co_tipo_demonstrativo", "Tipo de Demonstrativo:",
                               choices = c("RREO", "RREO Simplificado")),

                   selectizeInput("id_ente", "UFs (múltiplas):",
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

                   textInput("no_anexo", "Anexo (opcional):", "")
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
  source("R/extrator.R")

  dados_extraidos <- reactiveVal(NULL)

  observeEvent(input$buscar, {
    # Extração dos dados da API 
    df <- switch(endpoint,
      "anexos-relatorios" = extrair_dados_siconfi_anexos_relatorios(
                # sem query params
              ),
      "dca" = extrair_dados_siconfi_dca(
                an_exercicio = seq(input$ano_range[1], input$ano_range[2]),
                no_anexo = input$no_anexo,
                id_ente = input$id_ente
              ),
      "entes" = extrair_dados_siconfi_entes(
                # sem query params
              ),
      "extrato_entregas" = extrair_dados_siconfi_extrato_entregas(
                id_ente = input$id_ente,
                an_referencia = seq(input$ano_referencia[1], input$ano_referencia[2])
              ),
      "msc_controle" = extrair_dados_siconfi_msc_controle(
                id_ente = input$id_ente,
                an_referencia = seq(input$ano_referencia[1], input$ano_referencia[2]),
                me_referencia = input$me_referencia,
                co_tipo_matriz = input$co_tipo_matriz,
                classe_conta = input$classe_conta,
                id_tv = input$id_tv
              ),
      "msc_orcamentaria" = extrair_dados_siconfi_msc_orcamentaria(
                id_ente = input$id_ente,
                an_referencia = seq(input$ano_referencia[1], input$ano_referencia[2]),
                me_referencia = input$me_referencia,
                co_tipo_matriz = input$co_tipo_matriz,
                classe_conta = input$classe_conta,
                id_tv = input$id_tv
              ),
      "msc_patrimonial" = extrair_dados_siconfi_msc_patrimonial(
                id_ente = input$id_ente,
                an_referencia = seq(input$ano_referencia[1], input$ano_referencia[2]),
                me_referencia = input$me_referencia,
                co_tipo_matriz = input$co_tipo_matriz,
                classe_conta = input$classe_conta,
                id_tv = input$id_tv
              ),
      "rgf" = extrair_dados_siconfi_rgf(
                an_exercicio = seq(input$ano_range[1], input$ano_range[2]),
                in_periodicidade = input$in_periodicidade,
                nr_periodo = input$nr_periodo,
                co_tipo_demonstrativo = input$co_tipo_demonstrativo,
                no_anexo = input$no_anexo,
                co_esfera = input$co_esfera,
                co_poder = input$co_poder,
                id_ente = input$id_ente
              ),
      "rreo" = extrair_dados_siconfi_rreo(
                an_exercicio = seq(input$ano_range[1], input$ano_range[2]),
                nr_periodo = input$nr_periodo,
                co_tipo_demonstrativo = input$co_tipo_demonstrativo,
                no_anexo = input$no_anexo,
                co_esfera = input$co_esfera,
                id_ente = input$id_ente
              ),
      stop("Este endpoint é inválido ou não foi implementado.")
    )

    # Salva localmente
    if (!is.null(df)) {
      write.csv(df, caminho_csv, row.names = FALSE)
      showNotification("Extração finalizada com sucesso!", type = "message")
    } else {
      showNotification("Nenhum dado encontrado com esses filtros.", type = "warning")
    }

    # Armazena para visualização
    dados_extraidos(df)
  })

  # Exibir prévia
  output$preview <- renderTable({
    head(dados_extraidos(), 20)
  })

  # Download
  output$baixar <- downloadHandler(
    filename = function() {
      paste0("dados_siconfi_", Sys.Date(), ".csv")
    },
    content = function(file) {
      df <- dados_extraidos()
      if (!is.null(df)) write.csv(df, file, row.names = FALSE)
    }
  )
}
