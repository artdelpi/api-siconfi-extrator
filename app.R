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
                   uiOutput("params_coluna_1")
            ),
            column(6,
                   uiOutput("params_coluna_2")
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

  cod_ibge = c(
    "12 - Acre", "27 - Alagoas", "13 - Amazonas", "16 - Amapá", "29 - Bahia", 
    "23 - Ceará", "53 - Distrito Federal", "32 - Espírito Santo", "52 - Goiás", 
    "21 - Maranhão", "31 - Minas Gerais", "50 - Mato Grosso do Sul", "51 - Mato Grosso", 
    "15 - Pará", "25 - Paraíba", "26 - Pernambuco", "22 - Piauí", "41 - Paraná", 
    "33 - Rio de Janeiro", "24 - Rio Grande do Norte", "11 - Rondônia", "14 - Roraima", 
    "43 - Rio Grande do Sul", "42 - Santa Catarina", "28 - Sergipe", 
    "35 - São Paulo", "17 - Tocantins"
  )

  # Renderiza períodos do RGF de acordo com a periodicidade (Q ou S)
  output$nr_periodo_ui <- renderUI({
    req(input$in_periodicidade) # garante que existe input

    choices <- if (input$in_periodicidade == "Q") 1:3 else 1:2

    checkboxGroupInput("nr_periodo", "Período:",
                       choices = choices,
                       selected = choices)
  })

  observeEvent(input$buscar, tryCatch ({
    # Extração dos dados da API 
    df <- switch(input$endpoint,
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

    }, error = function(e) {
        showNotification(paste("Erro na extração: " e$message), type="error")
    }))

  output$params_coluna_1 <- renderUI ({
    switch(input$endpoint, 
      "anexos-relatorios" =  NULL, # sem query params

      "dca" = list(
        sliderInput("an_exercicio", "Período (Ano):",
                    min = 2015, max = as.numeric(format(Sys.Date(), "%Y")),
                    value = c(2023, 2024), sep = "", ticks = FALSE)
      ),

      "entes" = NULL, # sem query params

      "extrato_entregas" = list(
        sliderInput("an_referencia", "Período (Ano):",
                    min = 2015, max = as.numeric(format(Sys.Date(), "%Y")),
                    value = c(2023, 2024), sep = "", ticks = FALSE)
      ),

      "msc_controle" = list(
        sliderInput("an_referencia", "Período (Ano):",
                    min = 2015, max = as.numeric(format(Sys.Date(), "%Y")),
                    value = c(2023, 2024), sep = "", ticks = FALSE),
        checkboxGroupInput("me_referencia", "Mês:",
                           choices = 1:12,
                           selected = c(1, 2, 3))
      ),

      "msc_orcamentaria" = list(
        sliderInput("an_referencia", "Período (Ano):",
                    min = 2015, max = as.numeric(format(Sys.Date(), "%Y")),
                    value = c(2023, 2024), sep = "", ticks = FALSE),
        checkboxGroupInput("me_referencia", "Mês:",
                            choices = 1:12,
                            selected = c(1, 2, 3))
      ),

      "msc_patrimonial" = list(
        sliderInput("an_referencia", "Período (Ano):",
                    min = 2015, max = as.numeric(format(Sys.Date(), "%Y")),
                    value = c(2023, 2024), sep = "", ticks = FALSE),
        checkboxGroupInput("me_referencia", "Mês:",
                    choices = 1:12,
                    selected = c(1, 2, 3))
              ),

      "rgf" = list(
        sliderInput("an_exercicio", "Período (Ano):",
                    min = 2015, max = as.numeric(format(Sys.Date(), "%Y")),
                    value = c(2023, 2024), sep = "", ticks = FALSE),
        selectInput("in_periodicidade", "Periodicidade:", 
                    choices = c("S", "Q")),
        uiOutput("nr_periodo_ui") # período depende da periodicidade
        ),

      "rreo" = list(
        sliderInput("an_exercicio", "Período (Ano):",
                    min = 2015, max = as.numeric(format(Sys.Date(), "%Y")),
                    value = c(2023, 2024), sep = "", ticks = FALSE),
        checkboxGroupInput("nr_periodo", "Bimestres:",
                           choices = 1:6,
                           selected = c(1, 2, 3))
      ),

      stop("Este endpoint é inválido ou não foi implementado.")
    )
  })

  output$params_coluna_2 <- renderUI({
    switch(input$endpoint, 
          
      "anexos-relatorios" = NULL,  # sem query params

      "dca" = list(
        textInput("no_anexo", "Anexo (opcional):", ""),
        selectizeInput("id_ente", "UFs (múltiplas):", 
                      choices = cod_ibge, 
                      multiple = TRUE)
      ),

      "entes" = NULL,  # sem query params

      "extrato_entregas" = list(
        selectizeInput("id_ente", "UFs (múltiplas):", 
                      choices = cod_ibge, 
                      multiple = TRUE)
      ),

      "msc_controle" = list(
        selectizeInput("id_ente", "UFs (múltiplas):", 
                      choices = cod_ibge, multiple = TRUE),
        selectInput("co_tipo_matriz", "Tipo de Matriz:",
                    choices = c("MSCC", "MSCE")),
        selectInput("classe_conta", "Classe de Conta:",
                    choices = c("7", "8")),
        selectInput("id_tv", "Tipo de Valor:",
                    choices = c("beginning_balance", 
                                "ending_balance", 
                                "period_change"))
      ),

      "msc_orcamentaria" = list(
        selectizeInput("id_ente", "UFs (múltiplas):", 
                      choices = cod_ibge, multiple = TRUE),
        selectInput("co_tipo_matriz", "Tipo de Matriz:", 
                    choices = c("MSCC", "MSCE")),
        selectInput("classe_conta", "Classe de Conta:", 
                    choices = c("1", "2")),
        selectInput("id_tv", "Tipo de Valor:", 
                    choices = c("beginning_balance", 
                                "ending_balance", 
                                "period_change"))
      ),

      "msc_patrimonial" = list(
        selectizeInput("id_ente", "UFs (múltiplas):", 
                      choices = cod_ibge, multiple = TRUE),
        selectInput("co_tipo_matriz", "Tipo de Matriz:", 
                    choices = c("MSCC", "MSCE")),
        selectInput("classe_conta", "Classe de Conta:", 
                    choices = c("1", "2")),
        selectInput("id_tv", "Tipo de Valor:", 
                    choices = c("beginning_balance", 
                                "ending_balance", 
                                "period_change"))
      ),

      "rgf" = list(
        selectInput("co_tipo_demonstrativo", "Tipo de Demonstrativo:", 
                    choices = c("RGF", "RGF Simplificado")),
        textInput("no_anexo", "Anexo (opcional):", ""),
        selectInput("co_esfera", "Esfera:", 
                    choices = c("E", "M")),
        selectInput("co_poder", "Poder:", 
                    choices = c("1 - Executivo", 
                                "2 - Legislativo", 
                                "3 - Judiciário")),
        selectizeInput("id_ente", "UFs (múltiplas):", 
                      choices = cod_ibge, 
                      multiple = TRUE)
      ),

      "rreo" = list(
        selectInput("co_tipo_demonstrativo", "Tipo de Demonstrativo:", 
                    choices = c("RREO", "RREO Simplificado")),
        textInput("no_anexo", "Anexo (opcional):", ""),
        selectInput("co_esfera", "Esfera:", 
                    choices = c("M", "E", "U", "C")),
        selectizeInput("id_ente", "UFs (múltiplas):", 
                      choices = cod_ibge, 
                      multiple = TRUE)
      )
    )
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
