#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <math.h>

// random double in [0, a)
double randf(double a)
{
  return (double) rand() / (double) (RAND_MAX) * a;
}

void putv(double *v)
{
  printf("%.20f %.20f %.20f", v[0], v[1], v[2]);
}

void unit(double *v)
{
  double n = sqrt((v[0]*v[0]) + (v[1]*v[1]) + (v[2]*v[2]));
  v[0] /= n;
  v[1] /= n;
  v[2] /= n;
}

int main() {
  srand((unsigned int) time(NULL));

  double v[9];
  for(int i = 0; i < 1000000; i++)
  {
    for(int j = 0; j < 9; j++)
    {
      v[j] = randf(1.0);
    }
    
    unit(v);
    unit(v+3);
    unit(v+6);

    putv(v);
    putchar(' ');
    putv(v+3);
    putchar(' ');
    putv(v+6);
    putchar('\n');
  }
  
}
