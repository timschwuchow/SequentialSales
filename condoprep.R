#!/usr/bin/env R 

# Copyright 2018, Timothy John Schwuchow

library('foreign')
library('dplyr')

###############
## Functions ##
###############

gengroups <- function(...) { 
    return(as.numeric(factor(paste0(...)))) 
}

groupcount <- function(x) {
    fx <- factor(x)
    ave(x,x,FUN=length)
}

seqint <- function(x) { 
    seq.int(length(x)) 
} 

sortorder <- function(x,byvar,...) {
    df <- x 
    df$inid <- seq.int(nrow(df)) 
    dfsort <- df[order(...),]
    dfsort$order <- ave(dfsort[,byvar],factor(dfsort[,byvar]),FUN=seqint)
    dfout <- dfsort[order(dfsort$inid),]
    return(dfout$order)
}






#la.df <- read.dta('LAShort.dta')
#la.df <- rename(la.df,viewcode=sa_view_code,poolcode=sa_pool_code,arms=arms_length_flag_dfs,addr_raw=sr_site_addr_raw)

# Drop non-condos 

prepdata <- function(x) { 
    df <- x 
    df$rid <- seq.int(nrow(df)) 
    df <- df[df$usecode!="RCON",]
    # Drop if built before first year of data 
    df <- df[df$yrbld > 1988,]
    df <- df[df$yrbld != NA,]
    # Drop if price is low 
    df <- df[df$price >= 25000,]
    # Drop if not owner occupied
    # df <- df[df$occupancy == 1,]
    ## Drop if property was transacted more than once in a day     
    df$npdate <- groupcount(gengroups(df$property_id,df$sdate))
    df <- df[df$npdate==1,]
    df$npdate <- NULL 
    # Create sales order variable within property
    df$pidorder <- sortorder(df,'property_id',df$property_id,df$sdate)
    df <- df[df$pidorder==1,]
    
    
    
    
    
    
    
} 
    

