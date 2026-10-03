#FIGURES 1-3 (overview)

barplot(overview$exposed_properties, names.arg = c("1in30 River/Sea", "1in100 River/1in200 Sea"), xlab = "Flood scenario", ylab = "Number of exposed properties", col = c("green", "blue"), main = "Figure 1 - Number of Exposed Properties under each Flood Scenario")

barplot(overview$total_estimated_loss, names.arg = c("1in30 River/Sea", "1in100 River/1in200 Sea"), xlab = "Flood scenario", ylab = "Total estimated damage (£)", col = c("green", "blue"), main = "Figure 2 - Total Estimated Damage under each Flood Scenario", yaxt = "n")
axis(2, at = seq(0, 14000000, by = 2000000), labels = c("£0", "£2m", "£4m", "£6m", "£8m", "£10m", "£12m", "£14m"))

barplot(overview$mean_loss_per_property, names.arg = c("1in30 River/Sea", "1in100 River/1in200 Sea"), xlab = "Flood scenario", ylab = "Mean estimated damage per property (£)", col = c("green", "blue"), main = "Figure 3 - Mean Estimated Damage under each Flood Scenario",ylim=c(0,40000))

#FIGURE 4

# Combine the two scenarios
damage_combined <- rbind(
  data.frame(
    scenario = "1-in-30 River/Sea",
    estimated_loss_2026 = damage_1in30$estimated_loss_2026
  ),
  data.frame(
    scenario = "1-in-100 River/1-in-200 Sea",
    estimated_loss_2026 = damage_1in100_200$estimated_loss_2026
  )
)

# Explicitly set scenario order
damage_combined$scenario <- factor(
  damage_combined$scenario,
  levels = c(
    "1-in-30 River/Sea",
    "1-in-100 River/1-in-200 Sea"
  )
)

# Create damage bands
damage_combined$damage_band <- cut(
  damage_combined$estimated_loss_2026,
  breaks = c(0, 20000, 30000, 40000, 50000, 60000, Inf),
  labels = c(
    "<£20k",
    "£20k–£30k",
    "£30k–£40k",
    "£40k–£50k",
    "£50k–£60k",
    ">£60k"
  ),
  right = FALSE
)

# Count properties in each damage band
damage_distribution <- table(
  damage_combined$damage_band,
  damage_combined$scenario
)

# Plot distribution
barplot(
  t(damage_distribution),
  beside = TRUE,
  names.arg = c(
    "<£20k",
    "£20k–£30k",
    "£30k–£40k",
    "£40k–£50k",
    "£50k–£60k",
    ">£60k"
  ),
  xlab = "Estimated damage per property",
  ylab = "Number of properties",
  main = "Figure 4 - Distribution of Estimated Damage across Properties",
  col = c("green", "blue"), ylim= c(0,250)
)

legend(
  "topright",
  legend = c(
    "1-in-30 River/Sea",
    "1-in-100 River/1-in-200 Sea"
  ),
  fill = c("green", "blue")
)

#FIGURE 5

# Convert depth band to ordered numeric position
damage_depth <- rbind(
  data.frame(
    scenario = "1-in-30 River/Sea",
    depth_band = damage_1in30$depth_band,
    estimated_loss_2026 = damage_1in30$estimated_loss_2026
  ),
  data.frame(
    scenario = "1-in-100 River/1-in-200 Sea",
    depth_band = damage_1in100_200$depth_band,
    estimated_loss_2026 = damage_1in100_200$estimated_loss_2026
  )
)

damage_depth$depth_band <- factor(
  damage_depth$depth_band,
  levels = c(
    "<150mm",
    "150-300mm",
    "300-600mm",
    "600-900mm",
    "900-1200mm",
    "1200-2300mm",
    ">2300mm"
  )
)

# Separate the two scenarios
damage_depth_30 <- subset(
  damage_depth,
  scenario == "1-in-30 River/Sea"
)

damage_depth_100 <- subset(
  damage_depth,
  scenario == "1-in-100 River/1-in-200 Sea"
)

# Plot first scenario
plot(
  as.numeric(damage_depth_30$depth_band),
  damage_depth_30$estimated_loss_2026,
  xlim = c(0.5, 7.5),
  ylim = c(0, 65000),
  xaxt = "n",
  yaxt = "n",
  xlab = "Flood depth band",
  ylab = "Estimated damage per property (£)",
  main = "Figure 5 - Flood Depth and Estimated Damage at Property Level",
  pch = 16,
  col = "green"
)

# Add second scenario
points(
  as.numeric(damage_depth_100$depth_band),
  damage_depth_100$estimated_loss_2026,
  pch = 16,
  col = "blue"
)

# Custom x-axis
axis(
  1,
  at = 1:7,
  labels = c(
    "<150",
    "150-300",
    "300-600",
    "600-900",
    "900-1200",
    "1200-2300",
    ">2300"
  )
)

# Custom y-axis
axis(
  2,
  at = seq(0, 60000, by = 10000),
  labels = c(
    "£0",
    "£10k",
    "£20k",
    "£30k",
    "£40k",
    "£50k",
    "£60k"
  ),
  las = 1
)

legend(
  "topleft",
  legend = c(
    "1-in-30 River/Sea",
    "1-in-100 River/1-in-200 Sea"
  ),
  pch = 16,
  col = c("green", "blue")
)


#FIGURE 6

# Input scenario data
ep_data <- data.frame(
  return_period = c(1, 30, 100, Inf),
  aep = c(1, 1/30, 1/100, 0),
  loss = c(
    0,
    10942989,
    13736200,
    0
  )
)


# AAL calculation
# Sort by annual exceedance probability
ep_sorted <- ep_data[order(ep_data$aep), ]

# Trapezoidal integration
segment_areas <- diff(ep_sorted$aep) *
  (
    head(ep_sorted$loss, -1) +
      tail(ep_sorted$loss, -1)
  ) / 2

# Illustrative AAL
aal <- sum(segment_areas)

cat(
  "Illustrative AAL: £",
  format(round(aal, 0), big.mark = ","),
  "\n",
  sep = ""
)

# Increase margins
par(
  mar = c(7, 12, 4, 2) + 0.1,
  xpd = NA
)

plot(
  ep_sorted$aep * 100,
  ep_sorted$loss,
  type = "o",
  pch = 16,
  lwd = 2,
  xlab = "Annual exceedance probability (%)",
  ylab = "",
  main = "Figure 6- Illustrative Loss–Exceedance Probability Curve",
  xaxt = "n",
  yaxt = "n",
  ylim = c(0, 14000000)
)

# Y-axis

y_ticks <- seq(0, 14000000, by = 2000000)

axis(
  2,
  at = y_ticks,
  labels = paste0(
    "£",
    format(y_ticks, big.mark = ",", scientific = FALSE)
  ),
  las = 1
)

mtext(
  "Estimated total damage (£)",
  side = 2,
  line = 8
)


# Exact tick positions
x_ticks <- c(
  0,
  1,
  100 / 30,
  100
)

axis(
  1,
  at = x_ticks,
  labels = FALSE
)

# X-axis labels

text(
  x = 0,
  y = par("usr")[3] - 450000,
  labels = "0%",
  adj = c(0.5, 0.5)
)

# 1% - slightly higher
text(
  x = 1.4,
  y = par("usr")[3] - 150000,
  labels = "1%",
  adj = c(0, 0.5)
)

# 3.33% - lower again and slightly to the right
text(
  x = 100 / 30,
  y = par("usr")[3] - 450000,
  labels = "3.33%",
  adj = c(0, 0.5)
)

# 100%
text(
  x = 100,
  y = par("usr")[3] - 450000,
  labels = "100%",
  adj = c(0.5, 0.5)
)

# Scenario labels


text(
  1,
  13736200,
  labels = "1-in-100 river /\n1-in-200 sea",
  pos = 4,
  cex = 0.8
)

text(
  100 / 30,
  10942989,
  labels = "1-in-30 River/Sea",
  pos = 4,
  cex = 0.8
)


# AAL annotation


legend(
  "topright",
  legend = paste0(
    "Illustrative AAL = £",
    format(round(aal, 0), big.mark = ",")
  ),
  bty = "n"
)