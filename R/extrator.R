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


extrair_dados_siconfi_rreo <- function(){
    
}
