library(httr)
library(jsonlite)
library(dplyr)

#-------------------------------------------------------------
#        Funções principais de extração da API Siconfi                      
#-------------------------------------------------------------

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


extrair_dados_siconfi_dca <- function(an_exercicio,
                                      no_anexo,
                                      id_ente) {
    url_base = "https://apidatalake.tesouro.gov.br/ords/siconfi/tt/dca"

    df_list <- list() # df acumulador pra cada requisição

    for (ano in an_exercicio) {
        # Agrupa parâmetros de consulta
        query_params <- list(
            an_exercicio = ano,
            no_anexo = no_anexo,
            id_ente = id_ente
        )

        # Requisição HTTPS
        resposta <- tryCatch(
            GET(url=url_base, query=query_params),
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
        
        # Adiciona o data frame à lista de resultados
        df_list[[length(df_list)+1]] <- df 
                
        # Respeita limite da API (1 req/s)
        Sys.sleep(1)
    }

    # Combina dataframes acumulados
    df_final <- bind_rows(df_list)
    
    return(df_final)
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


extrair_dados_siconfi_extrato_entregas <- function(id_ente,
                                                   an_referencia) {
    url_base = "https://apidatalake.tesouro.gov.br/ords/siconfi/tt/extrato_entregas"
    
    df_list <- list() # df acumulador pra cada requisição

    for (ano in an_referencia) {
        # Agrupa parâmetros de consulta
        query_params <- list(
            id_ente = id_ente,
            an_referencia = ano
        )

        # Requisição HTTPS
        resposta <- tryCatch(
            GET(url=url_base, query=query_params),
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

        # Adiciona o data frame à lista de resultados
        df_list[[length(df_list)+1]] <- df 
                
        # Respeita limite da API (1 req/s)
        Sys.sleep(1)
    }

    # Combina dataframes acumulados
    df_final <- bind_rows(df_list)
    
    return(df_final)
}


extrair_dados_siconfi_msc_controle <- function(id_ente,
                                               an_referencia,
                                               me_referencia,
                                               co_tipo_matriz,
                                               classe_conta,
                                               id_tv) {
    url_base = "https://apidatalake.tesouro.gov.br/ords/siconfi/tt/msc_controle"

    df_list <- list() # df acumulador pra cada requisição

    for (ano in an_referencia) {
        for (mes in me_referencia) {
            for (uf in id_ente) {
                cat("Ano:", ano, "| Mês:", mes, "| UF:", uf, "\n")
                
                # Agrupa parâmetros de consulta
                query_params <- list(
                    id_ente = uf,
                    an_referencia = ano,
                    me_referencia = mes,
                    co_tipo_matriz = co_tipo_matriz,
                    classe_conta = classe_conta,
                    id_tv = id_tv
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


extrair_dados_siconfi_msc_orcamentaria <- function(id_ente,
                                                  an_referencia,
                                                  me_referencia,
                                                  co_tipo_matriz,
                                                  classe_conta,
                                                  id_tv) {
    url_base = "https://apidatalake.tesouro.gov.br/ords/siconfi/tt/msc_orcamentaria"

    df_list <- list() # df acumulador pra cada requisição

    for (ano in an_referencia) {
        for (mes in me_referencia) {
            for (uf in id_ente) {
                cat("Ano:", ano, "| Mês:", mes, "| UF:", uf, "\n")
                
                # Agrupa parâmetros de consulta
                query_params <- list(
                    id_ente = uf,
                    an_referencia = ano,
                    me_referencia = mes,
                    co_tipo_matriz = co_tipo_matriz,
                    classe_conta = classe_conta,
                    id_tv = id_tv
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


extrair_dados_siconfi_msc_patrimonial <- function(id_ente,
                                                  an_referencia,
                                                  me_referencia,
                                                  co_tipo_matriz,
                                                  classe_conta,
                                                  id_tv) {
    url_base = "https://apidatalake.tesouro.gov.br/ords/siconfi/tt/msc_patrimonial"

    df_list <- list() # df acumulador pra cada requisição

    for (ano in an_referencia) {
        for (mes in me_referencia) {
            for (uf in id_ente) {
                cat("Ano:", ano, "| Mês:", mes, "| UF:", uf, "\n")
                
                # Agrupa parâmetros de consulta
                query_params <- list(
                    id_ente = uf,
                    an_referencia = ano,
                    me_referencia = mes,
                    co_tipo_matriz = co_tipo_matriz,
                    classe_conta = classe_conta,
                    id_tv = id_tv
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


extrair_dados_siconfi_rgf <- function(an_exercicio,
                                      in_periodicidade,
                                      nr_periodo,
                                      co_tipo_demonstrativo,
                                      no_anexo,
                                      co_esfera,
                                      co_poder,
                                      id_ente) {
    url_base = "https://apidatalake.tesouro.gov.br/ords/siconfi/tt/rgf"

    df_list <- list() # df acumulador pra cada requisição

    for (ano in an_exercicio) {
        for (periodo in nr_periodo) {
            for (uf in id_ente) {
                cat("Ano:", ano, "| Período:", periodo, "| UF:", uf, "\n")
                
                # Agrupa parâmetros de consulta
                query_params <- list(
                    an_exercicio = ano,
                    in_periodicidade = in_periodicidade,
                    nr_periodo = periodo,
                    co_tipo_demonstrativo = co_tipo_demonstrativo,
                    no_anexo = no_anexo,
                    co_esfera = co_esfera,
                    co_poder = co_poder,
                    id_ente = uf
                )

                # Params opcionais se não forem vazios
                if (!is.null(no_anexo) && no_anexo != "" && length(no_anexo) == 1) {
                    query_params$no_anexo <- no_anexo
                }

                # Requisição HTTPS
                resposta <- tryCatch(
                    GET(url=url_base, query=query_params),
                    error = function(e) {
                        warning("Erro na requisição: ", conditionMessage(e))
                    }
                )

                # Verifica se a resposta é válida
                if(is.null(resposta) || resposta$status_code != 200) {
                    warning("Falha na resposta da API! Status:", 
                           ifelse(is.null(resposta), "NULL", resposta$status_code))
                    next # Pula iteração em vez de retornar NULL
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
    if (length(df_list) == 0) {
        warning("Nenhum dado encontrado")
        return(NULL)
    }
    
    return(df_final)
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
