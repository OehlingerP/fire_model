#' Calculates the area burned in the fire model. 
#' 
#' @param mat matrix; binary matrix where 1's indicate trees
#' @description
#' The fire model explains the spread of wildfires. The function area_burned() 
#'    calculates the total area burned in the model. In the model you define a 
#'    tree density and then you randomly populate a matrix with 0's and 1's 
#'    given the tree density. The fire than spreads from the fire line (first 
#'    column) to other trees if they border a burning tree. Fire can spread up/
#'    down, left/right but not diagonally.

area_burned <- function( mat ) {
  
  # find the index of trees in the matrix
  pos <- which(mat == 1, arr.ind = TRUE) # array index is an extremely useful argument for this
  
  # calculate the manhatten distance between trees trees are connected if the 
  # manhatten distance equals 1. Manhattan distance is super simple: see for 
  # example https://de.wikipedia.org/wiki/Manhattan-Metrik
  distance_mat <- as.matrix( dist( pos, method = "manhattan", diag = T ) )
  distance_mat[ upper.tri( distance_mat ) ] <- 0
  
  # create edges (how nodes (pos) are connected)
  edge <- which( distance_mat == 1, arr.ind = TRUE )
  
  # create graph and find components
  # create a graph/network of trees that are connected (we stored the connections in edge)
  graph <- igraph::graph_from_edgelist( edge, directed = FALSE )
  
  # find components of graph using the igraph package
  comp <- igraph::components( graph )
  
  # find components that are hit by fire
  # the part which( pos[ , 2 ] == 1 ) refers to trees in the first column of
  # the matrix as only those are hit initially by the fire
  # comp$membership assigns each tree to a component (group) of the network
  comp_burned <- unique( comp$membership[ which( pos[ , 2 ] == 1 ) ] )
  
  # calculate area burned in percent
  # comp$csize is the size of each component
  area_burned <- sum( comp$csize[ comp_burned ] ) / sum( mat ) * 100
  
  return( area_burned )
  
}

#' simulate the spread of wildfires

  # install igraph if not yet installed
  if( system.file(package = "igraph" ) == "" ) install.packages( "igraph" )

  set.seed( 20230526 )

  # create matrix to store results
  df_store <- as.data.frame( matrix( 0, nrow = 100, ncol = 99 ) )
  
  time <- numeric( 99 )
  
  # define matrix/forest size
  matrix_size <- 50
  
  for( density in 1:99 ){
    
    print( density )
    
    # save time for each step
    start_density <- Sys.time()
    
    for( i in 1:100 ){
      
      mat <- matrix( sample( c( 0, 1 ),
                             replace = TRUE,
                             size = matrix_size^2,
                             prob = c( 1-density/100,
                                       density/100 ) ),
                     ncol = matrix_size )
    
      df_store[ i, density ] <- area_burned( mat )
        
    }
    
    time[ density ] <- difftime( Sys.time(), start_density, units = "mins" )
    
    
  }
  
  getwd()
  
  save( df_store, time, file = "simulation_and_time.Rda" )

  # reformat data for plotting (I'll use ggplot2)
  colnames( df_store ) <- 1:99
  
  library( data.table )
  
  dt <- data.table::melt( as.data.table( df_store ) )
  
  dt[ , variable:=as.numeric( variable ) ]
  
  # calculate mean and standard deviation
  dt <- dt[ , .("mean" = mean(value,na.rm=T), "sd" =sd(value,na.rm=T)), by=variable]
  
  library( ggplot2 )
  
  plot <- ggplot( dt, aes( x = variable ) ) +
    geom_ribbon( aes( ymin = mean-sd, ymax = mean+sd ), alpha = 0.2 ) +
    geom_line( aes( y = mean ) )
  
  Rphd::gx_theme( plot )
  
  plot( time*60)

  plot( colMeans( df_store ) )

    