#!/usr/bin/env R 

# Copyright 2018, Timothy John Schwuchow

rm(list=ls())

library(jsonlite)
library(foreign) 
file1990 <- 'counties1990.json'
file2000 <- 'counties2000.json'


## Prepare 1990 data 
df1990 <- fromJSON(file1990)

df1990.names <- df1990[1,]
df1990.data <- df1990[-1,]

df1990 <- data.frame(state=df1990.data[,7],county=df1990.data[,8],medhhinc90=as.numeric(df1990.data[,1]),white=as.numeric(df1990.data[,2]),black=as.numeric(df1990.data[,3]),asian=as.numeric(df1990.data[,5]),other=as.numeric(df1990.data[,4])+as.numeric(df1990.data[,6]))

attach(df1990)

df1990$total <- white + black + asian + other
detach(df1990)
attach(df1990)
df1990$pctwhite90 <- white/total
df1990$pctblack90 <- black/total
df1990$pctasian90 <- asian/total 
df1990$pctother90 <- other/total 
detach(df1990)

df1990 <- df1990[,c('state','county','medhhinc90','pctwhite90','pctblack90','pctasian90','pctother90')]

## Prepare 2000 data 

df2000 <- fromJSON(file2000) 
df2000.names <- df2000[1,]
df2000.data <- df2000[-1,]

df2000 <- data.frame(state=df2000.data[,7],county=df2000.data[,8],medhhinc00=as.numeric(df2000.data[,1]),total=as.numeric(df2000.data[,2]),white=as.numeric(df2000.data[,3]),black=as.numeric(df2000.data[,4]),asian=as.numeric(df2000.data[,6]))

df2000$other <- df2000$total - df2000$white - df2000$black - df2000$asian 

attach(df2000)
df2000$pctwhite00 <- white / total 
df2000$pctblack00 <- black / total
df2000$pctasian00 <- asian / total 
df2000$pctother00 <- other / total 
detach(df2000) 

df2000 <- df2000[,c('state','county','medhhinc00','pctwhite00','pctblack00','pctasian00','pctother00')]

dfmerge <- merge(df1990,df2000,by=c('state','county'),all=T)

write.dta(dfmerge,'census.dta',version=11) 
write.csv(dfmerge,'census.csv') 

