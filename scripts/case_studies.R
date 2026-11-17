# 两个完整模拟案例，重新拟合并绘图 / Refit and plot both simulation cases.
# 从仓库根目录运行 / Run from the repository root: Rscript scripts/case_studies.R
library(ALSCL)
source('scripts/plot_helpers.R')
library(ggplot2)
library(patchwork)
source('scripts/simulation_workflow.R', encoding='UTF-8')
case_fit_bundle <- function(inputs,pa) {
  # F_sd 是创新 SD；拟合模型使用边际 SD / F_sd is innovation SD; fits use marginal SD.
  F_marginal_sd <- pa$F_sd / sqrt(1 - pa$F_ar^2)
  # 固定生物学与指定的过程假设 / Fix biology and stated process assumptions.
  pA <- list(log_Linf=log(pa$Linf),log_vbk=log(pa$vbk),t0=pa$t0,
    log_cv_len=log(pa$cv_L),log_std_log_F=log(F_marginal_sd),
    log_std_log_N0=log(pa$std_logN0),logit_log_R=qlogis(pa$R_ar))
  pB <- list(log_Linf=log(pa$Linf),log_vbk=log(pa$vbk),log_t0=log(pa$t0),
    log_cv_len=log(pa$cv_L),log_cv_grow=log(pa$cv_inc),log_sigma_log_F=log(F_marginal_sd),
    log_sigma_log_N0=log(pa$std_logN0),logit_log_R=qlogis(pa$R_ar))
  mA <- lapply(pA,function(v)factor(NA)); mB <- lapply(pB,function(v)factor(NA))
  mB$logit_log_F_l <- mB$logit_log_F_y <- factor(NA)
  prepare_alscl_data(inputs, fit_args=list(rec.age=pa$rec.age,nage=pa$nage,M=pa$M,
    sel_L50=pa$q_surv_L50,sel_L95=pa$q_surv_L95,len_mid=pa$len_mid,
    len_border=pa$len_border[-c(1,length(pa$len_border))],growth_step=pa$growth_step,
    train_times=2,ncores=1,silent=TRUE),
    fit_config=list(acl=list(parameters=pA,map=mA),
      alscl=list(parameters=pB,map=mB)))
}

run_case_studies <- function(out='docs') {
  # Committed figures and tables must come from the code of this checkout.
  if (grepl('^(\\./)?docs(/|$)', out)) {
    source('scripts/checkout_guard.R', local = TRUE)
    require_checkout_alscl()
  }
  cache <- Sys.getenv('ALSCL_MANUAL_CACHE')
  if(nzchar(cache)) options(ALSCL.tmb.cache=cache)
  old <- acl_theme(); on.exit(do.call(acl_theme_set,old),add=TRUE)
  # The package style; hand-built figures add theme_acl() and take colors from acl_palette().
  suppressMessages(acl_theme_reset())
  cols <- setNames(acl_theme('compare_colors'),c('ACL','ALSCL'))
  # A wider color bar keeps the labels of a bottom legend apart.
  wide_key <- theme(legend.key.width=unit(1.6,'cm'))
  fig <- file.path(out,'figures','cases'); dir.create(fig,recursive=TRUE,showWarnings=FALSE)
  # Size from acl_figure_size() unless given; 300 dpi.
  save_plot <- function(id,p,...) save_grid_free_plot(file.path(fig,paste0(id,'.png')),p,...)
  case_name <- c(flatfish='flatfish case',tuna='tuna case')
  quantity_names <- c(B='Total biomass',SSB='Spawning stock biomass (SSB)',Rec='Recruitment')
  statuses <- list()
  for(sp in c('flatfish','tuna')) {
    message('CASE ',sp)
    folder <- file.path(out,'data','cases',sp)
    z <- readRDS(file.path(folder,'truth.rds')); pa<-z$parameters; sm<-z$truth
    # 历史内附案例使用 2000 年起始 / Historical bundled cases start in 2000.
    inp <- simulation_to_tables(sm,pa,first_year=if(is.null(sm$years)) 2000 else NULL)
    bio <- sim_cal(pa)
    x <- case_fit_bundle(inp,pa)
    a <- run_acl(x)
    b <- run_alscl(x)
    status <- function(f,model) data.frame(Case=sp,Model=model,Code=f$convergence_code,
      MaxGradient=f$max_abs_gradient,pdHess=f$pdHess,Boundary=f$bound_hit)
    statuses[[sp]] <- rbind(status(a,'ACL'),status(b,'ALSCL'))
    years <- a$year
    obs <- data.frame(Year=rep(years,each=length(pa$len_mid)),
      Length=rep(pa$len_mid,length(years)),Value=as.vector(t(sm$SN_at_len)))
    save_plot(paste0(sp,'_data'),tidy_time_axis(ggplot(obs,aes(Year,Length,fill=log10(Value)))+
      geom_tile()+scale_fill_gradient(low='white',high=acl_palette(role='primary'))+
      labs(x='Year',y='Length (cm)',fill='Survey index (log10)',
        title=paste('Simulated survey index of the',case_name[[sp]]))+theme_acl()+wide_key,years))
    truth <- data.frame(Year=rep(years,3),Quantity=rep(c('B','SSB','Rec'),each=length(years)),
      Truth=c(sm$TB,sm$SSB,sm$Rec))
    estimates <- rbind(data.frame(Year=rep(years,3),Quantity=truth$Quantity,
      Value=c(a$report$B,a$report$SSB,a$report$Rec),Model='ACL'),
      data.frame(Year=rep(years,3),Quantity=truth$Quantity,
      Value=c(b$report$B,b$report$SSB,b$report$Rec),Model='ALSCL'))
    write_decimal_csv(truth,file.path(folder,'truth_timeseries.csv'),row.names=FALSE)
    write_decimal_csv(estimates,file.path(folder,'estimated_timeseries.csv'),row.names=FALSE)
    # The simulated values are a black dashed line in the same legend as the two fits.
    series <- rbind(estimates[c('Year','Quantity','Value','Model')],
      data.frame(Year=truth$Year,Quantity=truth$Quantity,Value=truth$Truth,Model='Simulated value'))
    series$Quantity <- factor(quantity_names[series$Quantity],levels=quantity_names)
    series$Model <- factor(series$Model,levels=c('ACL','ALSCL','Simulated value'))
    save_plot(paste0(sp,'_truth'),tidy_time_axis(ggplot(series,aes(Year,Value,colour=Model,linetype=Model))+
      geom_line()+expand_limits(y=0)+
      scale_colour_manual(values=c(cols,'Simulated value'='black'))+
      scale_linetype_manual(values=c(ACL='solid',ALSCL='solid','Simulated value'='dashed'))+
      facet_wrap(~Quantity,scales='free_y',ncol=1)+
      labs(x='Year',y='Estimate',colour=NULL,linetype=NULL,
        title=paste('Estimated and simulated population of the',case_name[[sp]]))+theme_acl(),years))
    growth <- data.frame(Age=pa$ages,Length=VB_func(pa$Linf,pa$vbk,pa$t0,pa$ages))
    prob <- rbind(data.frame(Length=pa$len_mid,Value=mat_func(pa$mat_L50,pa$mat_L95,pa$len_mid),Type='Proportion mature'),
      data.frame(Length=pa$len_mid,Value=bio$q_surv,Type='Survey catchability'))
    save_plot(paste0(sp,'_biology'),(ggplot(growth,aes(Age,Length))+geom_line(color=acl_palette(role='primary'))+
        expand_limits(y=0)+labs(x='Age (years)',y='Length (cm)',
          title=paste('Growth, maturity and survey catchability of the',case_name[[sp]]))+theme_acl())|
      (ggplot(prob,aes(Length,Value,color=Type))+geom_line()+
       scale_color_manual(values=setNames(acl_palette(2),c('Proportion mature','Survey catchability')))+
       labs(x='Length (cm)',y='Proportion',colour=NULL)+theme_acl()),
      # Two panels side by side; acl_figure_size() gives them too little height.
      width=10,height=4.6)
    if(sp=='tuna') {
      G <- b$report$G
      stopifnot(max(abs(colSums(G)-1))<1e-10,all(is.finite(G)),all(G>=0))
      g <- expand.grid(Destination=pa$len_mid,Source=pa$len_mid);g$Probability<-as.vector(G)
      save_plot('tuna_growth_transition',ggplot(g,aes(Source,Destination,fill=Probability))+
        geom_tile()+coord_equal()+scale_fill_gradient(low='white',high=acl_palette(role='primary'))+
        labs(x='Length at the start of a quarter (cm)',y='Length at the end of the quarter (cm)',
          title='ALSCL growth transition of the tuna case',
          subtitle='Each column sums to one; fish do not shrink')+theme_acl()+wide_key)
    }
  }
  checks <- do.call(rbind,statuses);print(checks)
  dir.create(file.path(out,'results'),recursive=TRUE,showWarnings=FALSE)
  write_decimal_csv(checks,file.path(out,'results','case_convergence.csv'),row.names=FALSE)
  stopifnot(all(checks$Code==0),all(checks$MaxGradient<.001),all(checks$pdHess),!any(checks$Boundary))
  invisible(checks)
}
if(sys.nframe()==0L) run_case_studies()
