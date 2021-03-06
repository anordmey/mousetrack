
#Replication of Dale & Duran 2011

rm(list=ls())

#load libraries
library(lme4)
library(ggplot2)
library(dplyr)
library(bootstrap)

#functions: 

#count function
n.unique <- function (x) {
  length(unique(x))
}

#Normalize coordinates
coords <- function(x) {
	x-x[1]
}

#xflips counts the number of times that the trajectory changes along the x axis.
xflips <- function(x) {
	dx <- -diff(x) #get changes in values 
	dx <- dx[dx!=0] #remove 0s to avoid dividing by zero
	
	flips <- dx/(abs(dx)) #get signs (-1 (decreasing), 0 (no change), 1 (increasing))
	flips <- diff(flips) #subtract changes from point to point
	xf <- length(flips[flips!=0])
	return(xf)
}

#acceleration components counts the number of times the trajectory speeds up or slows down.
#I'm not sure this is correct?
AC <- function(x, y, time) {
	dx <- diff(x)
	dy <- diff(y)
	dist <- sqrt(dx^2 + dy^2) #get distance between two points
	vel <- dist/diff(time) # calculate velocity
	acc <- diff(vel) #calculate acceleration 
	acc <- acc[acc!=0] #remove 0s to avoid dividing by zero
	
	acomps <- acc/(abs(acc)) #get signs (-1 (slowing down), 0 (no change), 1 (speeding up))
	acomps <- diff(acomps) #subtract changes from point to point
	ac <- length(acomps[acomps!=0]) - 1 #"The subtraction of 1 is to factor out the standard change in acceleration that is seen in a basic movement" (Dale & Duran,2011)
	return(ac)
}

# for bootstrapping 95% confidence intervals
theta <- function(x,xdata) {mean(xdata[x])}
ci.low <- function(x) {
  quantile(bootstrap(1:length(x),1000,theta,x)$thetastar,.025)}
ci.high <- function(x) {
  quantile(bootstrap(1:length(x),1000,theta,x)$thetastar,.975)}

  
########Two replication attempts 
###load data and prepare data frame from rep 1
long.data1 <- read.table("../data/negmouse.rep1.csv",
       sep=",",header=TRUE)
long.data1$subid <- paste(as.character(long.data1$subid),"a",sep="")

###load data and prepare data frame from rep 2       
long.data2 <- read.table("../data/negmouse.rep2.csv",
       sep=",",header=TRUE)
long.data2$subid <- paste(as.character(long.data2$subid),"b",sep="")

##Merge two data sets for these analyses
long.data <- rbind(long.data1, long.data2)

##I asked about what kind of mouse they used (mouse, trackpad, other).  
#Here I'm only removing people who responded "other"
long.data <- subset(long.data, mouse.type != "\"Other\"")

##Ns
#Initial data collection had n=60 in each condition
#I removed non-english speakers in a previous step, so the first rep had a total n = 119 and the second rep had a total n = 117
aggregate(subid ~ context.condition, long.data1, n.unique)
aggregate(subid ~ context.condition, long.data2, n.unique)

#Total N, after removing "other" mouse use, is 116 in each condition (original N was 60 per condition)
aggregate(subid ~ context.condition, long.data, n.unique)

#Setting up for data analysis    
long.data$subid <- factor(long.data$subid)
long.data$context.condition <- factor(long.data$context.condition, levels=c("no context","context"), labels=c("No Context","Context"))
long.data$sentence.type <- factor(long.data$sentence.type, levels=c("pos","neg"), labels=c("Positive","Negative"))
long.data$truth.val <- factor(long.data$truth.val, levels=c("TRUE","FALSE"), labels=c("True","False"))
long.data$mouse.type <- factor(long.data$mouse.type, levels = c("\"Mouse\"", "\"Trackpad\""), labels = c("mouse", "trackpad"))

#Normalize x & y coords
long.data <- long.data %>%
  group_by(subid, trial.num) %>%
  mutate(x = coords(xCoord),
         y = coords(-1*coords(yCoord))) %>%
  ungroup()
         
##Look at the raw data.  
##Make plot that shows picture of trajectories.  
subs <- long.data %>%
  filter(subid == "100a" | subid == "45a" | subid == "65b" | subid == "92b") %>% ##Just look at a couple of participants (these are just randomly selected participants)
  mutate(x = ifelse(left.side==FALSE, -1*x)) #Transform -1*x for any where True was on the right (so the picture always shows trajectories going to the left for true and the right for false)

qplot(y=y, x=x, linetype=sentence.type, color=truth.val,
      data=subs, geom="path") + 
  facet_grid(subid~trial.num) +
  theme_bw() 

##Exclusion criteria
long.data <- long.data %>%
  group_by(subid) %>% 
  mutate(propcorrect = mean(correct)) %>%
  filter(propcorrect > .8) %>% #reject participants with fewer than 80% correct
  ungroup() %>%
  filter(correct == 1) %>% #remove all incorrect trials
  group_by(context.condition) %>%
  filter(rt < (mean(rt) + sd(rt)*3) & rt > (mean(rt) - sd(rt)*3)) %>% #remove trials with motion times 3 standard deviations longer than mean motion time
  ungroup()

##Final Ns:
aggregate(subid ~ context.condition, long.data, n.unique)

###prepare data for analysis
#calculate xflips and AC count
#summarize data so that each row represents one trial (not one time point)
sdata <- long.data %>%
  group_by(context.condition, mouse.type, sentence.type, truth.val, item, subid) %>%
  summarize(xflips = xflips(x), 
         ac = AC(xCoord, y, timing),
         rt = (mean(rt))) %>%
  ungroup()

###Plot data
##xflips
#Original Data
old.xf <- as.data.frame(matrix(c("Positive","Negative","Positive","Negative","Positive","Negative","Positive","Negative","True","True","False","False","True","True","False","False","No Context","No Context","No Context","No Context","Context","Context","Context","Context",1.13,1.71,1.24,1.34,1.41,1.60,1.34,1.38), nrow=8, ncol=4))
names(old.xf) <- c("sentence.type","truth.val","context.condition","xflips")
old.xf$xflips <- as.numeric(as.character(old.xf$xflips))
old.xf$context.condition <- factor(old.xf$context.condition, levels=c("No Context","Context"))
old.xf$sentence.type <- factor(old.xf$sentence.type, levels=c("Positive","Negative"))
old.xf$truth.val <- factor(old.xf$truth.val, levels=c("True","False"))

ggplot(old.xf, aes(fill=truth.val, y=xflips, x=sentence.type)) +
	 geom_bar(position=position_dodge(), stat="identity") + 
	 facet_grid(~ context.condition) + 
	 coord_cartesian(ylim=c(0, 2.5)) + 
	 xlab("Sentence Type") + 
	 ylab("x-flips (#)") +
	 scale_fill_grey("Response") +
	 theme_bw()
	 
#Replication:
ms.xf <- sdata %>%
  group_by(context.condition, sentence.type, truth.val, subid) %>%
  summarize(m = mean(xflips)) %>%
  group_by(context.condition, sentence.type, truth.val) %>%
  summarize(cih = ci.high(m), 
            cil = ci.low(m), 
            m = mean(m))

ggplot(ms.xf, aes(fill=truth.val, y=m, x=sentence.type)) +
	 geom_bar(position=position_dodge(), stat="identity") + 
	 facet_wrap(~ context.condition) + 
	 geom_errorbar(aes(ymax=ms.xf$cih, ymin=ms.xf$cil), position=position_dodge(.9), width=0) +
	 coord_cartesian(ylim=c(0, 2.5)) + 
	 xlab("Sentence Type") + 
	 ylab("x-flips (#)") +
	 scale_fill_grey("Response") +
	 theme_bw() 
	 
#Does it matter if participants used a mouse or a trackpad?
ms.xf.mouse <- sdata %>%
  group_by(mouse.type, context.condition, sentence.type, truth.val, subid) %>%
  summarize(m = mean(xflips)) %>%
  group_by(mouse.type, context.condition, sentence.type, truth.val) %>%
  summarize(cih = ci.high(m), 
            cil = ci.low(m), 
            m = mean(m))

ggplot(ms.xf.mouse, aes(fill=truth.val, y=m, x=sentence.type)) +
  geom_bar(position=position_dodge(), stat="identity") + 
  facet_wrap(mouse.type ~ context.condition) + 
  geom_errorbar(aes(ymax=ms.xf.mouse$cih, ymin=ms.xf.mouse$cil), position=position_dodge(.9), width=0) +
  coord_cartesian(ylim=c(0, 2.5)) + 
  xlab("Sentence Type") + 
  ylab("x-flips (#)") +
  scale_fill_grey("Response") +
  theme_bw() 

#AC
#Original Data
old.ac <- matrix(c("Positive","Negative","Positive","Negative","Positive","Negative","Positive","Negative","True","True","False","False","True","True","False","False","No Context","No Context","No Context","No Context","Context","Context","Context","Context",1.56,2.86,2.16,2.27,2.30,2.66,2.07,2.51), nrow=8, ncol=4)
old.ac <- as.data.frame(old.ac)
names(old.ac) <- c("sentence.type","truth.val","context.condition","ac")
old.ac$ac <- as.numeric(as.character(old.ac$ac))
old.ac$context.condition <- factor(old.ac$context.condition, levels=c("No Context","Context"))
old.ac$sentence.type <- factor(old.ac$sentence.type, levels=c("Positive","Negative"))
old.ac$truth.val <- factor(old.ac$truth.val, levels=c("True","False"))

ggplot(old.ac, aes(fill=truth.val, y=ac, x=sentence.type)) +
  geom_bar(position=position_dodge(), stat="identity") + 
  facet_grid(~ context.condition) + 
  coord_cartesian(ylim=c(0, 8)) +
  xlab("Sentence Type") + 
  ylab("Acceleration Components (#)") +
  scale_fill_grey("Response") +
  theme_bw() + 
  theme(panel.grid.minor=element_blank(), panel.grid.major=element_blank(),legend.position=c(.12,.85),legend.title=element_blank())

#Replication:
ms.ac <- sdata %>%
  group_by(context.condition, sentence.type, truth.val, subid) %>%
  summarize(m = mean(ac)) %>%
  group_by(context.condition, sentence.type, truth.val) %>%
  summarize(cih = ci.high(m), 
            cil = ci.low(m), 
            m = mean(m))

ggplot(ms.ac, aes(fill=truth.val, y=m, x=sentence.type)) +
  geom_bar(position=position_dodge(), stat="identity") + 
  facet_grid(~ context.condition) + 
  geom_errorbar(aes(ymax=ms.ac$cih, ymin=ms.ac$cil), position=position_dodge(.9), width=.25, size=.25) +
  coord_cartesian(ylim=c(0, 22)) + 
  xlab("Sentence Type") +
  ylab("Acceleration Components (#)") +
  scale_fill_grey("Response") +
  theme_bw()

#Does it matter if participants used a mouse or a trackpad?
ms.ac.mouse <- sdata %>%
  group_by(mouse.type, context.condition, sentence.type, truth.val, subid) %>%
  summarize(m = mean(ac)) %>%
  group_by(mouse.type, context.condition, sentence.type, truth.val) %>%
  summarize(cih = ci.high(m), 
            cil = ci.low(m), 
            m = mean(m))

ggplot(ms.ac.mouse, aes(fill=truth.val, y=m, x=sentence.type)) +
  geom_bar(position=position_dodge(), stat="identity") + 
  facet_grid(mouse.type ~ context.condition) + 
  geom_errorbar(aes(ymax=ms.ac.mouse$cih, ymin=ms.ac.mouse$cil), position=position_dodge(.9), width=.0) +
  coord_cartesian(ylim=c(0, 22)) + 
  xlab("Sentence Type") +
  ylab("Acceleration Components (#)") +
  scale_fill_grey("Response") +
  theme_bw()

##RT
#Original paper does not report RT means

#Replication:
ms.rt <- sdata %>%
  group_by(context.condition, sentence.type, truth.val, subid) %>%
  summarize(m = mean(rt)) %>%
  group_by(context.condition, sentence.type, truth.val) %>%
  summarize(cih = ci.high(m), 
            cil = ci.low(m), 
            m = mean(m))

ggplot(ms.rt, aes(fill=truth.val, y=m, x=sentence.type)) +
	 geom_bar(position=position_dodge(), stat="identity") + 
	 facet_grid(~ context.condition) + 
	 geom_errorbar(aes(ymax=ms.rt$cih, ymin=ms.rt$cil), position=position_dodge(.9), width=.25, size=.25) +
	 xlab("Sentence Type") +
	 ylab("RT") +
	 scale_fill_grey("Response") +
	 theme_bw()




##Mixed effects models:
#These are all with maximal random effects structure that converges.

sdata$truth.val = factor(sdata$truth.val, levels=c("False","True"))

#split data
exp1 <- subset(sdata, context.condition=="No Context")
exp3 <- subset(sdata, context.condition=="Context")

##X-FLIPS
#EXPERIMENT 1
xflips.exp1 <- lmer(xflips ~ sentence.type*truth.val + (sentence.type + truth.val | subid) + (truth.val | item), data=exp1)
summary(xflips.exp1)

#EXPERIMENT3
xflips.exp3 <- lmer(xflips ~ sentence.type*truth.val + (sentence.type + truth.val | subid) + (truth.val | item), data=exp3)	
summary(xflips.exp3)

#What if we only look at mouse users?
#Removes a big chunk of participants:
aggregate(subid ~ context.condition + mouse.type, sdata, n.unique)

#EXPERIMENT 1
xflips.exp1.mouseonly <- lmer(xflips ~ sentence.type*truth.val + (sentence.type + truth.val | subid) + (truth.val | item), data=subset(exp1, mouse.type == "mouse"))
summary(xflips.exp1.mouseonly)

#EXPERIMENT3
xflips.exp3.mouseonly <- lmer(xflips ~ sentence.type*truth.val + (sentence.type + truth.val | subid) + (truth.val | item), data=subset(exp3, mouse.type == "mouse"))
summary(xflips.exp3.mouseonly)



###ACCELERATION COMPONENTS
#EXPERIMENT 1
ac.exp1 <- lmer(ac ~ sentence.type*truth.val + (sentence.type*truth.val | subid) + (truth.val | item), data=exp1)
summary(ac.exp1)

##EXPERIMENT 3
ac.exp3 <- lmer(ac ~ sentence.type*truth.val + (sentence.type*truth.val | subid) + (truth.val | item), data=exp3)
summary(ac.exp3)

#What if we only look at mouse users?
#EXPERIMENT 1
ac.exp1.mouseonly <- lmer(ac ~ sentence.type*truth.val + (sentence.type*truth.val | subid) + (truth.val | item), data=subset(exp1, mouse.type=="mouse"))
summary(ac.exp1.mouseonly)

##EXPERIMENT 3
ac.exp3.mouseonly <- lmer(ac ~ sentence.type*truth.val + (sentence.type*truth.val | subid) + (truth.val | item), data=subset(exp3, mouse.type == "mouse"))
summary(ac.exp3.mouseonly)



##COMPARE BOTH EXPERIMENTS
xf.compare <- lmer(xflips ~ sentence.type*truth.val*context.condition + (sentence.type+truth.val| subid) + (sentence.type+truth.val| item), data=sdata)
summary(xf.compare)

ac.compare <- lmer(ac ~ sentence.type*truth.val*context.condition + (sentence.type+truth.val| subid) + (sentence.type+truth.val| item), data=sdata)
summary(ac.compare)

rt.compare <- lmer(rt ~ sentence.type*truth.val*context.condition + (sentence.type+truth.val| subid) + (sentence.type+truth.val| item), data=sdata)
summary(rt.compare)
