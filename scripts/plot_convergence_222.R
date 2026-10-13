# Plot the recorded 2.2.2 checks; run after the convergence validation script.
x <- read.csv("output/release-222/convergence-checks.csv")
png("output/release-222/convergence.png", width = 1500, height = 800, res = 160)
par(mar = c(5, 13, 3, 1))
y <- rev(seq_len(nrow(x)))
plot(x$gradient_before, y, log = "x", xlim = c(1e-10, .02), ylim = c(.5, 4.5),
  yaxt = "n", pch = 1, cex = 1.3, col = "#64748b", ylab = "",
  xlab = "Maximum absolute gradient (log scale)",
  main = "ALSCL 2.2.2: t0-only synthetic-data fits")
axis(2, at = y, labels = paste(x$model,
  ifelse(x$F_structure == "year", "shared F", "group x year F")), las = 1)
segments(x$gradient_before, y, x$gradient_after, y, col = "#64748b", lwd = 2)
points(x$gradient_after, y, pch = ifelse(x$numerical_ok, 19, 4),
  col = ifelse(x$numerical_ok, "#087f8c", "#ba3d2f"), cex = 1.5, lwd = 2)
abline(v = 1e-3, lty = 3, col = "#999999")
legend("topleft", legend = c("Before refinement", "After: screen passed", "After: boundary case"),
  pch = c(1, 19, 4), col = c("#64748b", "#087f8c", "#ba3d2f"), bty = "n", cex = .85)
dev.off()
