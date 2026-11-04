#include "elasticflow.h"
#include "dynamatic/Integration.h"

int elasticflow(in_int_t x[N]) {
  int s = 1;
  for (int i = 0; i < N; i++) {
    if (x[i] > 0)
      s = s * x[i];
    else
      s = s + x[i];
  }
  return s;
}

int main(void) {
  in_int_t x[N];
  unsigned seed = 1u;
  for (int j = 0; j < N; ++j) {
    seed = seed * 1103515245u + 12345u;
    unsigned pick = (seed >> 16) % 100u;
    seed = seed * 1103515245u + 12345u;
    if (pick < (unsigned)POS_PERCENT)
      x[j] = 1 + (int)((seed >> 16) % 3u);
    else
      x[j] = -(int)((seed >> 16) % 4u);
  }
  CALL_KERNEL(elasticflow, x);
  return 0;
}
