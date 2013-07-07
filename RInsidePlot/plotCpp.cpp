#include <RInside.h> // embedded R via RInside

int main(int argc, char *argv[]) {
  RInside R(argc, argv); // create an embedded R instance
  
  // evaluate an R expression with curve()
  std::string cmd = "tmpf <- tempfile('curve'); "
    "png(tmpf); curve(x^2, -10, 10, 200); "
    "dev.off(); tmpf";

  // by running parseEval, we get ﬁlename back
  std::string tmpfile = R.parseEval(cmd);
  std::cout << "Could use plot in " << tmpfile << std::endl;
  unlink(tmpfile.c_str()); // cleaning up

  // alternatively, by forcing a display we can plot to screen
  cmd = "x11(); curve(x^2, -10, 10, 200); Sys.sleep(30);";
  R.parseEvalQ(cmd);
  exit(0);
}
