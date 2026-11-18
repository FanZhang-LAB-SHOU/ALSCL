# GitHub 图谱：所有拟合图使用内置 YTF_example / All fitted plots use YTF_example.
# 从仓库根目录运行 / Run from the repository root:
# Rscript scripts/ytf_workflow.R
# 拟合结果另存到 output/ytf-guide/fits.rds，重绘时不必重新拟合。
# The fits are also saved to output/ytf-guide/fits.rds.
# run_ytf_guide(fits = readRDS("output/ytf-guide/fits.rds")) redraws every figure
# from them without refitting, and scripts/palette_swatches.R and
# scripts/plot_sparse_panels.R take the file as their teaching fits.
# The figures and tables must come from the code of this checkout. The guard
# loads the checkout with pkgload, or stops when the installed package has
# different functions, templates or data. A version number cannot show that.
source("scripts/checkout_guard.R")
use_checkout_alscl()
library(ggplot2)
library(patchwork)
source("scripts/plot_helpers.R")

run_ytf_guide <- function(out = "docs", npeels = 3L, fits = NULL,
                          fits_file = file.path("output", "ytf-guide", "fits.rds")) {
  cache <- Sys.getenv("ALSCL_MANUAL_CACHE")
  if (nzchar(cache)) options(ALSCL.tmb.cache = cache)
  for (d in c("figures/ytf", "results", "data"))
    dir.create(file.path(out, d), recursive=TRUE, showWarnings=FALSE)
  data("YTF_example", package="ALSCL")
  x <- YTF_example
  inputs <- x[c("data.CatL", "data.wgt", "data.mat")]
  # 固定生物参数的教学拟合 / Conditional teaching fits with known biology.
  message("Fitting YTF ACL")
  a <- if (is.null(fits)) run_acl(x, train_times = 2, ncores = 1, silent = TRUE) else fits$acl
  message("Fitting YTF ALSCL")
  b <- if (is.null(fits)) run_alscl(x, train_times = 2, ncores = 1, silent = TRUE) else fits$alscl
  # Older teaching caches omitted their recipe. Reattach the original YTF
  # inputs through the public archive interface before drawing portable fits.
  if (!is.null(fits)) {
    restore_recipe <- function(fit) {
      if (!is.null(fit$recipe)) return(fit)
      path <- tempfile(fileext = ".rds")
      on.exit(unlink(path), add = TRUE)
      save_assessment(fit, path, x = x)
      read_assessment(path)
    }
    a <- restore_recipe(a)
    b <- restore_recipe(b)
  }
  dat <- inputs$data.CatL
  status <- function(f, name) data.frame(Model=name, Code=f$convergence_code,
    MaxGradient=f$max_abs_gradient, pdHess=f$pdHess, Boundary=f$bound_hit)
  convergence <- rbind(status(a,"ACL"),status(b,"ALSCL"))
  print(convergence)
  stopifnot(all(convergence$Code==0), all(convergence$MaxGradient<.001),
            all(convergence$pdHess), !any(convergence$Boundary))
  write_decimal_csv(convergence,file.path(out,"results","convergence.csv"),row.names=FALSE)
  for (name in names(inputs)) write_decimal_csv(inputs[[name]],
    file.path(out,"data",paste0(name,".csv")),row.names=FALSE)
  write_decimal_csv(diagnose_model(dat,a),file.path(out,"results","diagnostics_ACL.csv"),row.names=FALSE)
  write_decimal_csv(diagnose_model(dat,b),file.path(out,"results","diagnostics_ALSCL.csv"),row.names=FALSE)
  cmp <- compare_models(a,b,dat)
  for (nm in c("summary","growth","fit_metrics","correlation"))
    write_decimal_csv(cmp[[nm]],file.path(out,"results",paste0("comparison_",nm,".csv")),row.names=FALSE)
  # 返回图和数据的示例 / Access plotting data explicitly.
  tab <- plot_abundance(b,type="NL",return_data=TRUE)
  stopifnot(is.list(tab),!is.null(tab$plot))
  old_theme <- acl_theme()
  on.exit(do.call(acl_theme_set, old_theme),add=TRUE)
  acl_theme_set(font_family="sans",title_size=12,
    axis_title_size=10,axis_text_size=9,strip_text_size=9)
  n_figures <- 0L
  # Saved at 300 dpi with the size of acl_figure_size() unless width or height is given.
  render <- function(id, p, width = NULL, height = NULL) {
    message("FIGURE ", id)
    save_grid_free_plot(file.path(out, "figures", "ytf", paste0(id, ".png")), p,
                        width = width, height = height)
    n_figures <<- n_figures + 1L
  }
for(typ in c('length','year')) for(ex in c(FALSE,TRUE)) {
 ylab <- if (ex) 'Survey index' else 'Log survey index'
 if (typ == 'length') {
  render(paste0('CatL_',typ,'_',ex),plot_CatL(b,facet_by='length',exp_transform=ex,point_size=1,ylab=ylab))
 } else {
  render(paste0('CatL_',typ,'_',ex),plot_CatL(b,facet_by='year',exp_transform=ex,line_size1=.6,line_size2=.4,ylab=ylab))
 }
}
for(fun in c('plot_abundance','plot_biomass','plot_SSB','plot_catch')) {
 types<-switch(fun,plot_abundance=c('N','NA','NL'),plot_biomass=c('B','BA','BL'),plot_SSB=c('SSB','SBA','SBL'),plot_catch=c('CN','CNA','CNL'))
 for(typ in types) render(paste0(fun,'_',typ),do.call(fun,list(b,type=typ,se=TRUE)))
}
# 相对渔获量：模型值与模拟真值都除以各自的均值 / Relative catch: the model and the simulated truth, each divided by its mean.
render('relative_catch',plot_relative_catch(b,observed=data.frame(year=b$year,catch=x$truth$CB),type='weight',observed_name='Simulated catch'))
render('recruitment',plot_recruitment(b,se=TRUE))
render('SSB_Rec',plot_SSB_Rec(b,age_at_recruitment=1))
# 模拟的年龄鉴定资料，并非论文实测；体长先归入模型体长组，再求各年龄均值 / Synthetic age readings, not observations of the paper; each length is assigned to its model length bin before averaging.
set.seed(42); ref<-data.frame(Age=rep(1:15,each=5)); ref$Length<-VB_func(60,.2,1/60,ref$Age)+rnorm(nrow(ref),0,2)
ref$Mid<-b$len_mid[findInterval(ref$Length,b$len_border)+1]
readings<-data.frame(age=1:15,mean_length=as.numeric(tapply(ref$Mid,ref$Age,mean)),sd_length=as.numeric(tapply(ref$Mid,ref$Age,sd)))
render('VB',plot_VB(b,observed=readings,parameter_curve=TRUE))
render('length_at_age',plot_length_at_age(b,ages=c(2,5,8,11)))
render('pla',plot_pla(b),height=6.5)
for(model in c('ACL','ALSCL'))for(typ in c('year','age','length')) {
 if(model=='ACL' && typ=='length') next # ACL has no F at length; type = 'length' is an alias of 'age'
 fit<-if(model=='ACL')a else b
 render(paste('F',model,typ,sep='_'),plot_fishing_mortality(fit,type=typ,se=TRUE))
}
# 拟合所用的固定输入 / Fixed inputs of the fit.
render('inputs',(plot_natural_mortality(b,title='Natural mortality rate')+expand_limits(y=0))|plot_survey_catchability(b,point_size=1.5,title='Survey catchability at length'),height=4.6)
for(typ in c('length','year')) render(paste0('residuals_',typ),plot_residuals(b,facet_by=typ))
for(typ in c('R','F'))for(lg in c(TRUE,FALSE))
 render(paste0('deviation_',typ,'_',lg),plot_deviance(b,type=typ,log=lg,se=TRUE,point_size=1.2))
render('ridges',plot_ridges(b))
render('compare_ts',plot_compare_ts(a,b,se=TRUE),height=5.6)
render('compare_F',plot_compare_F(a,b))
render('compare_residuals',plot_compare_residuals(a,b,dat))
# 调整组合图排版，不改变估计值 / Adjust the layout without changing estimates.
# Age 15 is the plus group, labelled 15+ as in the left panel.
growth_display <- function(p) {
 p[[2]] <- p[[2]] + scale_x_continuous(breaks=c(1,5,10,15),labels=c('1','5','10','15+'))
 p
}
# 参考生长点也是模拟数据 / Reference growth points are synthetic too.
set.seed(42); ref<-data.frame(Age=rep(1:15,each=5)); ref$Length<-VB_func(60,.2,1/60,ref$Age)+rnorm(nrow(ref),0,2)
render('compare_growth',growth_display(plot_compare_growth(a,b,age_range=c(1,15),ref_data=ref,ref_name='Simulated age readings',nls_start=list(Linf=60,k=.2,t0=1/60))),height=5)
render('compare_CatL',plot_compare_CatL(a,b,dat,years=c(2000,2005,2010,2015)),height=6)
render('compare_metrics',plot_compare_metrics(a,b,dat))
render('compare_selectivity',plot_compare_selectivity(a,b))
for(method in c('apical','mean'))render(paste0('compare_F_',method),plot_compare_F_ts(a,b,method=method,title=if(method=='apical')'Apical fishing mortality rate by time step' else 'Mean fishing mortality rate by time step'))
# 回溯逐次删除末端时间步 / Peel successive terminal time steps.
retro_a <- if (is.null(fits)) retro_acl(x, nyear=npeels, train_times=2, ncores=1, silent=TRUE) else fits$retro_acl
retro_b <- if (is.null(fits)) retro_alscl(x, nyear=npeels, train_times=2, ncores=1, silent=TRUE) else fits$retro_alscl
render('retro_ACL',plot_retro(retro_a,rho_digits=3,rho_size=3,point_size=1),height=6)
render('retro_ALSCL',plot_retro(retro_b,rho_digits=3,rho_size=3,point_size=1),height=6)
write_decimal_csv(retro_a$fit_diagnostics,file.path(out,'results','retro_diagnostics_ACL.csv'),row.names=FALSE)
write_decimal_csv(retro_b$fit_diagnostics,file.path(out,'results','retro_diagnostics_ALSCL.csv'),row.names=FALSE)
write_decimal_csv(retro_a$rho_text,file.path(out,'results','rho_ACL.csv'),row.names=FALSE)
write_decimal_csv(retro_b$rho_text,file.path(out,'results','rho_ALSCL.csv'),row.names=FALSE)

  # 以模拟真值检查估计的实际含义 / Compare with the generating truth.
  years <- a$year
  truth <- data.frame(Year=rep(years,3),Quantity=rep(c("B","SSB","Rec"),each=length(years)),
                      Truth=c(x$truth$TB,x$truth$SSB,x$truth$Rec))
  estimates <- rbind(data.frame(Year=rep(years,3),Quantity=truth$Quantity,
    Value=c(a$report$B,a$report$SSB,a$report$Rec),Model="ACL"),
    data.frame(Year=rep(years,3),Quantity=truth$Quantity,
    Value=c(b$report$B,b$report$SSB,b$report$Rec),Model="ALSCL"))
  # The simulated values are a black dashed line in the same legend as the two fits.
  quantity_names <- c(B="Total biomass",SSB="Spawning stock biomass (SSB)",Rec="Recruitment")
  series <- rbind(estimates,data.frame(Year=truth$Year,Quantity=truth$Quantity,
    Value=truth$Truth,Model="Simulated value"))
  series$Quantity <- factor(quantity_names[series$Quantity],levels=quantity_names)
  series$Model <- factor(series$Model,levels=c("ACL","ALSCL","Simulated value"))
  render("truth",
    tidy_time_axis(ggplot(series,aes(Year,Value,colour=Model,linetype=Model))+geom_line()+
      expand_limits(y=0)+
      scale_colour_manual(values=c(setNames(acl_theme("compare_colors"),c("ACL","ALSCL")),"Simulated value"="black"))+
      scale_linetype_manual(values=c(ACL="solid",ALSCL="solid","Simulated value"="dashed"))+
      facet_wrap(~Quantity,scales="free_y",ncol=1)+theme_acl()+
      labs(x="Year",y="Estimate",colour=NULL,linetype=NULL,
        title="Estimated and simulated population of YTF_example"),years))
  write_decimal_csv(truth,file.path(out,"results","truth.csv"),row.names=FALSE)
  write_decimal_csv(estimates,file.path(out,"results","estimates.csv"),row.names=FALSE)
  writeLines(trimws(capture.output(sessionInfo()), which="right"),file.path(out,"results","sessionInfo.txt"))
  message("COMPLETE: ",n_figures," YTF figures")
  result <- list(acl=a,alscl=b,retro_acl=retro_a,retro_alscl=retro_b,inputs=inputs)
  # 保存新拟合（不含当前会话的 TMB 对象）/ Save new fits without the session's TMB objects.
  # run_ytf_guide(fits = readRDS(fits_file)) redraws every figure without refitting.
  if (is.null(fits) && !is.null(fits_file)) {
    dir.create(dirname(fits_file), recursive=TRUE, showWarnings=FALSE)
    saved <- result
    saved$acl$obj <- saved$alscl$obj <- NULL
    saveRDS(saved, fits_file)
    message("Saved the fits to ", fits_file)
  }
  invisible(result)
}
if (sys.nframe() == 0L) run_ytf_guide()
