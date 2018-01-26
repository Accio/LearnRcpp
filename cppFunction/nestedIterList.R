library(Rcpp)
library(testthat)
library(rbenchmark)

## a minimal example of implementing a nested loop in C++ with iterators, in which the nested iterator starts at the next position of the outer iterator
cppFunction(
'Rcpp::List nestList() {
  std::list< std::vector<int> > myList;
  
  for(int i=0; i<10; ++i) {
    std::vector<int> set;
    for(int j=0; j<10-i; ++j) {
      set.push_back(j);
    }
    myList.push_back(set);
  } 

   // iterate through myList
   for(std::list< std::vector<int> >::iterator it=myList.begin(); it!=myList.end(); ++it) {
     for(std::list< std::vector<int> >::iterator it2=it; it2!=myList.end(); ++it2) {
      if(it2==it) {
        it2++;
        if(it2==myList.end()) 
          break;
      } 
      Rcpp::Rcout << "[first] n=" << it->size() << ", [second] n=" << it2->size() << std::endl;
     }
   }
   
   return(Rcpp::wrap(myList));
}')

nestList()
