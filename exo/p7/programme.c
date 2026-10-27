/* Part 7: test program compiled with "RISC-V (32-bits) gcc (trunk)" on godbolt.org,
   options -O0 -march=rv32im -mabi=ilp32.
   No global variable and no library call: the data are on the stack, in the quadram.
   Expected result in a0 (x10): 285 + 720 + 21 = 1026. */

int factorielle(int n)
{
    int r = 1;
    for (int i = 2; i <= n; i++)
        r = r * i;
    return r;
}

int pgcd(int a, int b)
{
    while (b != 0) {
        int t = a % b;
        a = b;
        b = t;
    }
    return a;
}

int main(void)
{
    int carres[10];
    int somme = 0;
    for (int i = 0; i < 10; i++)
        carres[i] = i * i;
    for (int i = 0; i < 10; i++)
        somme += carres[i];                              /* 285 */
    return somme + factorielle(6) + pgcd(1071, 462);    /* 285 + 720 + 21 */
}
