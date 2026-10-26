# Refresh legacy help assets and the own-data figures from saved assessments.
# First run scripts/ytf_workflow.R (save returned fits) and the own-data example.
# Rscript scripts/refresh_manual_figures.R [ytf_fits.rds] [own_assessment.rds]
library(ALSCL)
library(ggplot2)
library(patchwork)
args <- commandArgs(TRUE)
ytffile <- if (length(args)) args[1] else 'output/release-225/gallery/fits.rds'
ownfile <- if (length(args)>1) args[2] else 'output/own-data-example/assessment_summary.rds'
z <- readRDS(ytffile); a <- z$acl; b <- z$alscl
acl_theme_reset()
acl_theme_set(base_theme='bw',font_family='sans',title_size=12,
              axis_title_size=10,axis_text_size=9,strip_text_size=9,palette='npg')
source('scripts/plot_helpers.R')
save_plot <- function(path,p,width=11,height=8.5) {
  save_grid_free_plot(path,p,width=width,height=height,dpi=160,bg='white')
  message('REFRESH ',path)
}
# These old filenames are retained for bookmarks and previously written help.
# Their figures now reuse the checked current YTF gallery.
aliases <- c(
 plot_CatL_length='CatL_length_FALSE',plot_CatL_year='CatL_year_FALSE',
 plot_SBL='plot_SSB_SBL',plot_SSB='plot_SSB_SSB',plot_SSB_Rec='SSB_Rec',
 plot_VB='VB',plot_abundance_N='plot_abundance_N',plot_abundance_NA='plot_abundance_NA',
 plot_abundance_NL='plot_abundance_NL',plot_biomass_B='plot_biomass_B',
 plot_biomass_BL='plot_biomass_BL',plot_catch_CN='plot_catch_CN',plot_catch_CNA='plot_catch_CNA',
 plot_fishing_mortality_age='F_ALSCL_age',plot_fishing_mortality_year='F_ALSCL_year',
 plot_pla='pla',plot_recruitment='recruitment',plot_residuals_length='residuals_length',
 plot_residuals_year='residuals_year',plot_ridges='ridges',
 readme_alscl_catl='CatL_year_TRUE',readme_alscl_recruitment='recruitment',
 readme_alscl_residuals='residuals_year',readme_alscl_ridges='ridges',
 readme_alscl_ssb='plot_SSB_SSB',readme_catl_fit='CatL_year_TRUE',
 readme_compare_F='compare_F',readme_compare_growth='compare_growth',
 readme_compare_metrics='compare_metrics',readme_compare_residuals='compare_residuals',
 readme_compare_selectivity='compare_selectivity',readme_compare_ts='compare_ts',
 readme_residuals='residuals_year')
for (name in names(aliases)) stopifnot(file.copy(
  file.path('docs/figures/ytf',paste0(aliases[[name]],'.png')),
  file.path('man/figures',paste0(name,'.png')),overwrite=TRUE))
acl_plots <- list(
 readme_acl_catl=plot_CatL(a,type='year',exp_transform=TRUE,facet_ncol=4),
 readme_acl_pla=plot_pla(a),readme_acl_recruitment=plot_recruitment(a,se=TRUE),
 readme_acl_residuals=plot_residuals(a,type='year',facet_ncol=4),
 readme_acl_ridges=plot_ridges(a),readme_acl_ssb=plot_SSB(a,se=TRUE),
 readme_acl_vb=plot_VB(a,age_range=c(1,15),se=TRUE))
for (name in names(acl_plots)) save_plot(file.path('man/figures',paste0(name,'.png')),acl_plots[[name]])
heatmaps <- plot_compare_F(a,b)
for (i in 1:2) {
  panel <- heatmaps
  panel$data <- subset(heatmaps$data,Model==c('ACL','ALSCL')[i])
  panel <- panel + labs(y=if(i==1) 'Age' else 'Length',
                        title=paste(c('ACL','ALSCL')[i],'fishing mortality'))
  save_plot(file.path('man/figures',paste0('readme_',c('acl','alscl')[i],'_F_heatmap.png')),panel,height=5)
}
expected <- paste0(c(names(aliases),names(acl_plots),'readme_acl_F_heatmap','readme_alscl_F_heatmap'),'.png')
actual <- setdiff(list.files('man/figures',pattern='\\.png$'),'ACLlogo.png')
stopifnot(setequal(expected,actual))
# Preserve the fitted estimates; only create fresh plots with the current theme.
own <- readRDS(ownfile)$ALSCL
save_plot('docs/figures/own-data-example/residuals.png',
          plot_residuals(own,type='year',facet_ncol=4,x_breaks=pretty(own$len_mid,n=4)),width=10,height=8)
save_plot('docs/figures/own-data-example/SSB.png',plot_SSB(own,se=isTRUE(own$pdHess)),width=8,height=5)
cat('Refreshed',length(expected),'legacy help figures and two own-data figures.\n')
