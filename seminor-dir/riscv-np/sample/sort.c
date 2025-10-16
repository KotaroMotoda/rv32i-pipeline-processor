int main() {
    int a = 1;
    int b = 2;
    int c = 3;
    int d = 4;
    int e = 5;
    int f = 6;
    
    // データハザードが起こらない命令列
    // 各変数の結果が使用されるまで3命令以上の間隔を確保
    
    int r1 = a + b;       // add x10, x11, x12  (r1 = 1 + 2 = 3)
    int r2 = c + d;       // add x13, x14, x15  (r2 = 3 + 4 = 7)
    int r3 = e + f;       // add x16, x17, x18  (r3 = 5 + 6 = 11)
    int r4 = a - b;       // sub x19, x11, x12  (r4 = 1 - 2 = -1)
    
    // ここまでで4命令経過、r1が安全に使用可能
    int r5 = r1 + c;      // add x20, x10, x14  (r5 = 3 + 3 = 6)
    int r6 = r2 + d;      // add x21, x13, x15  (r6 = 7 + 4 = 11)
    int r7 = r3 + e;      // add x22, x16, x17  (r7 = 11 + 5 = 16)
    int r8 = r4 - f;      // sub x23, x19, x18  (r8 = -1 - 6 = -7)
    
    // さらに4命令経過、r5が安全に使用可能
    int r9 = r5 + r6;     // add x24, x20, x21  (r9 = 6 + 11 = 17)
    int r10 = r7 - r8;    // sub x25, x22, x23  (r10 = 16 - (-7) = 23)
    
    return r9 + r10;      // add x10, x24, x25  (return 17 + 23 = 40)
}