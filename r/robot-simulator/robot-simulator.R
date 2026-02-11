orientation <- c("NORTH" = 1, "EAST" = 2, "SOUTH" = 3, "WEST" = 4)

new_robot <- function(coordinates, direction) {
  structure(list("coordinates" = coordinates, "direction" = direction),
    class = "robot"
  )
}

move <- function(a_robot, commands) {
  UseMethod("move")
}
# nolint start
move.robot <- function(a_robot, commands) {
  dir <- orientation[a_robot$direction]
  for (step in unlist(strsplit(commands, split = ""))) {
    if (step == "R") {
      dir <- dir + 1
    } else if (step == "L") {
      dir <- dir - 1
    } else {
      if (dir %% 2 == 0) {
        if (dir %% 4 == 0) a_robot$coordinates[1] <- a_robot$coordinates[1] - 1
        else a_robot$coordinates[1] <- a_robot$coordinates[1] + 1
      } else {
        if (dir %% 4 == 3) a_robot$coordinates[2] <- a_robot$coordinates[2] - 1
        else a_robot$coordinates[2] <- a_robot$coordinates[2] + 1
      }
    }
  }
  a_robot$direction <- names(orientation[if (dir %% 4 != 0) dir %% 4 else 4])
  a_robot
}
# nolint end
