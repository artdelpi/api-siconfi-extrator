library(httr)
library(jsonlite)
library(dplyr)

#------------------------------------------------------------
#        Função principal de extração da API Siconfi               
#------------------------------------------------------------

extrair_dados_siconfi_anexos_relatorios <- function(){
    url_base <- "https://apidatalake.tesouro.gov.br/ords/siconfi/tt/anexos-relatorios"

    # Requisição HTTPS
    resposta <- tryCatch(
        GET(url=url_base),
        error = function(e) {
            warning("Erro na requisição: ", conditionMessage(e))
            return(NULL)
        }
    )
    
    # Verifica se a resposta é válida
    if(is.null(resposta) || resposta$status_code != 200) {
        warning("Falha na resposta da API!")
        return(NULL)
    } 
    
    # Parse do JSON (carga útil)
    dados <- fromJSON(content(resposta, as="text", encoding="UTF-8"))

    # Retorna os dados estruturados
    df <- as.data.frame(dados$items)
    return(df)
}


extrair_dados_siconfi_dca <- function(){

}


extrair_dados_siconfi_entes <- function(){
    url_base <- "https://apidatalake.tesouro.gov.br/ords/siconfi/tt/entes"

    # Requisição HTTPS
    resposta <- tryCatch(
        GET(url=url_base),
        error = function(e) {
            warning("Erro na requisição: ", conditionMessage(e))
            return(NULL)
        }
    )
    
    # Verifica se a resposta é válida
    if(is.null(resposta) || resposta$status_code != 200) {
        warning("Falha na resposta da API!")
        return(NULL)
    } 
    
    # Parse do JSON (carga útil)
    dados <- fromJSON(content(resposta, as="text", encoding="UTF-8"))

    # Retorna os dados estruturados
    df <- as.data.frame(dados$items)
    return(df)
}


extrair_dados_siconfi_extrato_entregas <- function(){

}


extrair_dados_siconfi_msc_controle <- function(){

}


extrair_dados_siconfi_msc_orcamentaria <- function(){

}


extrair_dados_siconfi_msc_patrimonial <- function(){

}


extrair_dados_siconfi_rgf <- function(){

}


extrair_dados_siconfi_rreo <- function(an_exercicio,
                                       nr_periodo,
                                       co_tipo_demonstrativo,
                                       no_anexo,
                                       co_esfera,
                                       id_ente) {

    url_base = "https://apidatalake.tesouro.gov.br/ords/siconfi/tt/rreo"

    df_list <- list() # df acumulador pra cada requisição

    for (ano in an_exercicio) {
        for (bimestre in nr_periodo) {
            for (uf in id_ente) {
                cat("Ano:", ano, "| Bimestre:", bimestre, "| UF:", uf, "\n")
                
                # Agrupa parâmetros de consulta
                query_params <- list(
                    an_exercicio = ano,
                    nr_periodo = bimestre,
                    co_tipo_demonstrativo = co_tipo_demonstrativo,
                    no_anexo = no_anexo,
                    co_esfera = co_esfera,
                    id_ente = uf
                )

                # Requisição HTTPS
                resposta <- tryCatch(
                    GET(url=url_base, query=query_params),
                    error = function(e) {
                        warning("Erro na requisição: ", conditionMessage(e))
                    }
                )

                # Verifica se a resposta é válida
                if(is.null(resposta) || resposta$status_code != 200) {
                    warning("Falha na resposta da API!")
                    return(NULL)
                } 

                # Parse do JSON (carga útil)
                dados <- fromJSON(content(resposta, as="text", encoding="UTF-8"))

                # Estrutura os dados
                df <- as.data.frame(dados$items)

                # Adiciona o data frame à lista de resultados
                df_list[[length(df_list)+1]] <- df 
                
                # Respeita limite da API (1 req/s)
                Sys.sleep(1)
            }           
        }
    }

    # Combina dataframes acumulados
    df_final <- bind_rows(df_list)
    
    return(df_final)
}
