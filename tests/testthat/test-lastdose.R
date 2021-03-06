

context("basic functionality")
set_file <- system.file("csv", "setn.csv", package = "lastdose")
df <- read.csv(set_file)
set1 <- subset(df, set==1)
set2 <- subset(df, set==2 & ID==1 & time <= 12)


test_that("doses at time zero", {
  x <- lastdose(set1)
  expect_true(exists("TAD", x))
  expect_true(exists("LDOS", x))
  expect_identical(unique(x[["LDOS"]]), c(0,100))
  a <- c(0,0,4,8,12,4,8,12)
  expect_identical(x[["TAD"]],c(a,a))
  a <- c(0,rep(100,7))
  expect_identical(x[["LDOS"]],c(a,a))
})

test_that("time ties (q12h dosing)", {
  x <- lastdose(set1)
  z <- lastdose(set1, addl_ties = "dose_first")
  expect_false(identical(x,z))
  ax <- subset(x, time==12)
  az <- subset(z, time==12)
  expect_true(all(ax[["TAD"]] == 12))
  expect_true(all(az[["TAD"]] == 0))
})

test_that("don't fill back", {
  x <- lastdose(set1, back_calc = FALSE)
  a <- c(-99,0,4,8,12,4,8,12)
  expect_identical(x[["TAD"]],c(a,a))
})

test_that("customize fill", {
  x <- lastdose(set1, back_calc = FALSE, fill = NA_real_)
  a <- c(NA_real_,0,4,8,12,4,8,12)
  expect_identical(x[["TAD"]],c(a,a))
})

test_that("doses don't start at time zero", {
  x <- lastdose(set2)
  a <- c(seq(-6,0),seq(0,6))
  expect_identical(x[["TAD"]],as.double(a))
})

test_that("lastdose_df", {
  x <- lastdose_df(set1)
  y <- lastdose_list(set1)
  expect_identical(x[["tad"]], y[["tad"]])
})

test_that("lastdose_list", {
   y <- lastdose_list(set1)
  expect_is(y,"list")
  expect_identical(names(y), c("tad", "ldos"))
})

test_that("required columns", {
  x <- set1
  x[["amt"]] <- NULL
  expect_error(lastdose(x))
  x <- set1
  x[["time"]] <- NULL
  expect_error(lastdose(x))
  x <- set1
  x[["ID"]] <- NULL
  expect_error(lastdose(x))
  x <- set1
  x[["evid"]] <- NULL
  expect_error(lastdose(x))
})

test_that("non-numeic data throws error", {
  for(col in c("ID","time", "addl", "ii", "evid", "ID", "amt")) {
    dd <- set1[seq(10),]
    dd[[col]] <- "A"
    expect_error(lastdose(dd))
  }
})

test_that("records out of order throws error", {
  set1$time[12] <- 1E6
  expect_error(lastdose(set1))
})

test_that("tad and ldos are NA when time is NA", {
  set1$time[12] <- NA_real_
  ans <- lastdose(set1)[12,]
  expect_true(is.na(ans[["TAD"]]))
  expect_true(is.na(ans[["LDOS"]]))
  expect_true(is.na(ans[["time"]]))
})

test_that("error for missing values in ID,evid,ii,addl", {
  for(col in c("ID", "evid", "ii", "addl")) {
    dd <- set1[seq(10),]
    dd[[col]] <- NA_real_
    expect_error(lastdose(dd))
  }
})

test_that("NA amt is error for dosing rec, ok otherwise", {
  dd <- set1
  dd$amt[5] <- NA_real_
  expect_is(lastdose(dd), "data.frame")
  dd <- set1
  dd$amt[10] <- NA_real_
  expect_error(lastdose(dd))
})
